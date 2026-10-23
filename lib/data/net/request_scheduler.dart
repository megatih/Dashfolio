import 'dart:async';
import 'dart:collection';
import 'dart:math';

import '../../core/clock.dart';

/// Who is asking. User-initiated work jumps ahead of the refresh pipeline, which jumps ahead of lazy work.
enum RequestPriority { user, refresh, lazy }

/// Token-bucket parameters: [burst] requests may be sent back to back, then [perSecond] on average.
class RateLimit {
  const RateLimit({required this.burst, required this.perSecond});

  /// No throttling (tests, or hosts we do not need to pace).
  static const unlimited = RateLimit(burst: 1 << 30, perSecond: 1e9);

  final int burst;
  final double perSecond;
}

class SchedulerStats {
  int requests = 0;
  int retries = 0;
  int rateLimited = 0;
  int cacheHits = 0;

  @override
  String toString() => 'requests=$requests retries=$retries 429s=$rateLimited cacheHits=$cacheHits';
}

class _Waiter {
  _Waiter(this.priority, this.seq, this.ready);
  final RequestPriority priority;
  final int seq;
  final Completer<void> ready;
}

/// Per-host request pacing shared by every client: a token bucket plus a concurrency cap (priority ordered), in-flight
/// de-duplication, `Retry-After`-aware backoff with full jitter, and a circuit breaker for repeated rate limiting.
///
/// Callers decide what is retried; the scheduler only paces, de-duplicates and remembers rate-limit history.
class RequestScheduler {
  RequestScheduler({
    this.name = 'http',
    this.clock = const SystemClock(),
    this.limit = RateLimit.unlimited,
    this.maxConcurrent = 4,
    this.circuitBase = const Duration(seconds: 60),
    this.circuitMax = const Duration(minutes: 10),
    this.circuitThreshold = 2,
    this.backoffBase = const Duration(milliseconds: 400),
    this.maxRetryAfter = const Duration(seconds: 60),
    Random? random,
  }) : _random = random ?? Random(),
       _tokens = limit.burst.toDouble();

  final String name;
  final Clock clock;
  final RateLimit limit;
  final int maxConcurrent;
  final Duration circuitBase;
  final Duration circuitMax;

  /// Consecutive rate-limited requests (after retries) that open the circuit.
  final int circuitThreshold;
  final Duration backoffBase;
  final Duration maxRetryAfter;
  final Random _random;
  final stats = SchedulerStats();

  // ---- pacing --------------------------------------------------------------

  double _tokens;
  DateTime? _refilledAt;
  int _active = 0;
  int _seq = 0;
  Timer? _timer;
  final _waiters = SplayTreeSet<_Waiter>((a, b) {
    final p = a.priority.index.compareTo(b.priority.index);
    return p != 0 ? p : a.seq.compareTo(b.seq);
  });

  void _refill() {
    final now = clock.now();
    final last = _refilledAt;
    _refilledAt = now;
    if (last == null) return;
    final elapsed = now.difference(last).inMicroseconds / Duration.microsecondsPerSecond;
    if (elapsed > 0) _tokens = min(limit.burst.toDouble(), _tokens + elapsed * limit.perSecond);
  }

  void _pump() {
    _timer?.cancel();
    _timer = null;
    while (_waiters.isNotEmpty && _active < maxConcurrent) {
      _refill();
      if (_tokens < 1) {
        final wait = Duration(microseconds: ((1 - _tokens) / limit.perSecond * Duration.microsecondsPerSecond).ceil() + 1000);
        _timer = Timer(wait, _pump);
        return;
      }
      _tokens -= 1;
      _active++;
      final w = _waiters.first;
      _waiters.remove(w);
      w.ready.complete();
    }
  }

  /// Runs [task] once a token and a concurrency slot are available.
  Future<T> schedule<T>(Future<T> Function() task, {RequestPriority priority = RequestPriority.refresh}) async {
    final w = _Waiter(priority, _seq++, Completer<void>());
    _waiters.add(w);
    _pump();
    await w.ready.future;
    stats.requests++;
    try {
      return await task();
    } finally {
      _active--;
      _pump();
    }
  }

  // ---- de-duplication ------------------------------------------------------

  final Map<String, Future<Object?>> _inflight = {};

  /// Shares one in-flight [factory] future between callers with the same [key].
  Future<T> dedupe<T>(String key, Future<T> Function() factory) {
    final existing = _inflight[key];
    if (existing != null) {
      stats.cacheHits++;
      return existing as Future<T>;
    }
    final f = factory();
    _inflight[key] = f;
    f.whenComplete(() {
      _inflight.remove(key); // block body: returning the future would make it await itself
    }).ignore();
    return f;
  }

  // ---- backoff and circuit -------------------------------------------------

  /// Delay before retry number [attempt] (0-based): the server's `Retry-After` when given, else full jitter.
  Duration backoff(int attempt, {Duration? retryAfter}) {
    stats.retries++;
    if (retryAfter != null) return retryAfter > maxRetryAfter ? maxRetryAfter : retryAfter;
    final ceiling = backoffBase.inMilliseconds * pow(2, attempt).toInt();
    return Duration(milliseconds: _random.nextInt(ceiling + 1));
  }

  Future<void> sleepBackoff(int attempt, {Duration? retryAfter}) => Future<void>.delayed(backoff(attempt, retryAfter: retryAfter));

  /// Parses a `Retry-After` header (delta-seconds or HTTP date).
  Duration? parseRetryAfter(String? header) {
    if (header == null) return null;
    final secs = int.tryParse(header.trim());
    if (secs != null) return Duration(seconds: secs < 0 ? 0 : secs);
    final date = DateTime.tryParse(header.trim());
    if (date == null) return null;
    final d = date.difference(clock.now());
    return d.isNegative ? Duration.zero : d;
  }

  DateTime? _circuitUntil;
  int _consecutiveRateLimits = 0;
  int _trips = 0;

  bool get circuitOpen => _circuitUntil != null && clock.now().isBefore(_circuitUntil!);

  /// Call when a request ultimately failed with 429 (after retries).
  void recordRateLimited() {
    stats.rateLimited++;
    _consecutiveRateLimits++;
    if (_consecutiveRateLimits >= circuitThreshold) {
      final scaled = circuitBase * pow(2, _trips).toInt();
      final open = scaled > circuitMax ? circuitMax : scaled;
      _circuitUntil = clock.now().add(open);
      _trips++;
    }
  }

  void recordSuccess() {
    _consecutiveRateLimits = 0;
    _trips = 0;
    _circuitUntil = null;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

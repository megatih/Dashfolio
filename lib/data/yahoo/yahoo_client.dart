import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../core/failure.dart';
import '../net/request_scheduler.dart';
import 'crumb_manager.dart';
import 'yahoo_config.dart';
import 'yahoo_mappers.dart';

final _log = Logger('YahooClient');

/// Overrides the scheduler's jittered backoff (tests pass a no-op).
typedef BackoffDelay = Future<void> Function(int attempt);

/// Low-level Yahoo Finance HTTP client: retries, crumb handling, de-duplication
/// and a simple rate-limit circuit breaker. Returns decoded JSON objects.
class YahooClient {
  YahooClient({
    required this.dio,
    required this.config,
    CrumbManager? crumbManager,
    this.maxAttempts = 3,
    this.backoff,
    this.clock = const SystemClock(),
    Duration circuitOpenFor = const Duration(seconds: 60),
    RequestScheduler? scheduler,
  }) : _crumb = crumbManager,
       scheduler =
           scheduler ?? RequestScheduler(name: 'yahoo', clock: clock, limit: yahooRateLimit, maxConcurrent: 4, circuitBase: circuitOpenFor);

  /// Yahoo is unofficial and rate limits aggressively: roughly 2 requests/second with a small burst.
  static const yahooRateLimit = RateLimit(burst: 4, perSecond: 2);

  final Dio dio;
  final YahooConfig config;
  final CrumbManager? _crumb;
  final int maxAttempts;
  final BackoffDelay? backoff;
  final Clock clock;
  final RequestScheduler scheduler;

  bool get circuitOpen => scheduler.circuitOpen;

  /// Max symbols per `/v7/finance/quote` call.
  static const quoteBatchSize = 50;

  Future<Json> chart(String symbol, {String? range, String interval = '1d', int? period1, int? period2}) {
    final q = <String, String>{
      'interval': interval,
      'events': 'div,splits',
      'includePrePost': 'false',
      'range': ?range,
      'period1': ?period1?.toString(),
      'period2': ?period2?.toString(),
    };
    return _get('/v8/finance/chart/${Uri.encodeComponent(symbol)}', q);
  }

  Future<Json> quote(Iterable<String> symbols) => _get('/v7/finance/quote', {'symbols': symbols.join(',')}, needsCrumb: true);

  Future<Json> search(String query, {int quotes = 10, int news = 8}) =>
      _get('/v1/finance/search', {'q': query, 'quotesCount': '$quotes', 'newsCount': '$news'}, priority: RequestPriority.user);

  Future<Json> quoteSummary(String symbol) => _get(
    '/v10/finance/quoteSummary/${Uri.encodeComponent(symbol)}',
    {'modules': 'summaryDetail,defaultKeyStatistics,assetProfile,calendarEvents'},
    needsCrumb: true,
    priority: RequestPriority.lazy,
  );

  Future<Json> _get(String path, Map<String, String> query, {bool needsCrumb = false, RequestPriority priority = RequestPriority.refresh}) {
    if (config.misconfigured) {
      return Future.error(const ConfigFailure('Web build needs a Yahoo proxy URL (YAHOO_PROXY_URL)'));
    }
    final key = '$path?${(query.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').join('&')}';
    return scheduler.dedupe(key, () => _request(path, query, needsCrumb && !config.viaProxy, priority));
  }

  Future<Json> _request(String path, Map<String, String> query, bool needsCrumb, RequestPriority priority) async {
    if (circuitOpen) throw const RateLimitedFailure('Yahoo is rate limiting requests; try again shortly');
    AppFailure last = const NetworkFailure();
    Duration? retryAfter;
    var crumbRetried = false;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final q = {...query};
        if (needsCrumb) q['crumb'] = await _crumb!.get();
        final res = await scheduler.schedule(
          () => dio.get<String>(
            '${config.baseFor(attempt)}$path',
            queryParameters: q,
            options: Options(
              headers: {'User-Agent': YahooConfig.userAgent, 'Accept': 'application/json'},
              responseType: ResponseType.plain,
              validateStatus: (_) => true,
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          ),
          priority: priority,
        );
        final status = res.statusCode ?? 0;
        final body = res.data ?? '';

        if (status == 200) {
          scheduler.recordSuccess();
          return decodeJson(body);
        }
        if ((status == 401 || status == 403) && needsCrumb && !crumbRetried) {
          crumbRetried = true;
          _crumb!.invalidate();
          last = const UnauthorizedFailure();
          attempt--; // crumb refresh does not consume an attempt
          continue;
        }
        if (status == 404) {
          // Chart/quoteSummary 404s carry a JSON error payload the mappers translate.
          try {
            return decodeJson(body);
          } on AppFailure {
            throw const NotFoundFailure();
          }
        }
        if (status == 429) {
          last = const RateLimitedFailure();
          retryAfter = scheduler.parseRetryAfter(res.headers.value('retry-after'));
        } else if (status >= 500) {
          last = const NetworkFailure('Yahoo Finance is temporarily unavailable');
        } else if (status == 401 || status == 403) {
          throw const UnauthorizedFailure();
        } else {
          throw NetworkFailure('Unexpected response ($status)');
        }
        _log.warning('HTTP $status for $path (attempt ${attempt + 1}/$maxAttempts)');
      } on DioException catch (e) {
        _log.warning('Network error for $path: ${e.type}');
        last = const NetworkFailure();
      }
      if (attempt < maxAttempts - 1) {
        await (backoff?.call(attempt) ?? scheduler.sleepBackoff(attempt, retryAfter: retryAfter));
        retryAfter = null;
      }
    }

    if (last is RateLimitedFailure) scheduler.recordRateLimited();
    throw last;
  }
}

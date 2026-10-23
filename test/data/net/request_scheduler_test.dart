import 'dart:async';
import 'dart:math';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pacing', () {
    test('lets a burst through immediately, then paces to the refill rate', () async {
      final s = RequestScheduler(limit: const RateLimit(burst: 2, perSecond: 20), maxConcurrent: 10);
      addTearDown(s.dispose);
      final sw = Stopwatch()..start();
      final times = await Future.wait([for (var i = 0; i < 5; i++) s.schedule(() async => sw.elapsedMilliseconds)]);
      expect(times.where((t) => t < 25).length, 2, reason: 'only the burst is immediate: $times');
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(120)); // 3 more tokens at 20/s = 150 ms
      expect(s.stats.requests, 5);
    });

    test('never runs more than maxConcurrent tasks at once', () async {
      final s = RequestScheduler(maxConcurrent: 2);
      var active = 0, peak = 0;
      await Future.wait([
        for (var i = 0; i < 6; i++)
          s.schedule(() async {
            peak = max(peak, ++active);
            await Future<void>.delayed(const Duration(milliseconds: 5));
            active--;
          }),
      ]);
      expect(peak, 2);
    });

    test('user work runs before refresh work, which runs before lazy work', () async {
      final s = RequestScheduler(maxConcurrent: 1);
      final order = <String>[];
      final gate = Completer<void>();
      final first = s.schedule(() => gate.future);
      final lazy = s.schedule(() async => order.add('lazy'), priority: RequestPriority.lazy);
      final refresh = s.schedule(() async => order.add('refresh'));
      final user = s.schedule(() async => order.add('user'), priority: RequestPriority.user);
      gate.complete();
      await Future.wait([first, lazy, refresh, user]);
      expect(order, ['user', 'refresh', 'lazy']);
    });

    test('a failing task frees its slot', () async {
      final s = RequestScheduler(maxConcurrent: 1);
      await expectLater(s.schedule<void>(() async => throw StateError('x')), throwsStateError);
      expect(await s.schedule(() async => 1), 1);
    });
  });

  group('dedupe', () {
    test('shares one in-flight future per key and forgets it afterwards', () async {
      final s = RequestScheduler();
      var calls = 0;
      Future<int> work() async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return calls;
      }

      final results = await Future.wait([s.dedupe('k', work), s.dedupe('k', work), s.dedupe('other', work)]);
      expect(calls, 2);
      expect(results[0], results[1]);
      expect(await s.dedupe('k', work), 3);
      expect(s.stats.cacheHits, 1);
    });

    test('a failed call is not cached', () async {
      final s = RequestScheduler();
      await expectLater(s.dedupe<int>('k', () async => throw StateError('x')), throwsStateError);
      expect(await s.dedupe('k', () async => 7), 7);
    });
  });

  group('backoff', () {
    test('honours Retry-After, capped, and otherwise uses full jitter within the exponential ceiling', () {
      final s = RequestScheduler(random: Random(1), backoffBase: const Duration(milliseconds: 100));
      expect(s.backoff(0, retryAfter: const Duration(seconds: 3)), const Duration(seconds: 3));
      expect(s.backoff(0, retryAfter: const Duration(hours: 1)), const Duration(seconds: 60));
      for (var attempt = 0; attempt < 4; attempt++) {
        final d = s.backoff(attempt);
        expect(d.inMilliseconds, inInclusiveRange(0, 100 * pow(2, attempt).toInt()));
      }
      expect(s.stats.retries, 6);
    });

    test('parses Retry-After seconds and HTTP dates', () {
      final clock = FixedClock(DateTime.utc(2024, 1, 1, 12));
      final s = RequestScheduler(clock: clock);
      expect(s.parseRetryAfter('7'), const Duration(seconds: 7));
      expect(s.parseRetryAfter(null), isNull);
      expect(s.parseRetryAfter('soon'), isNull);
      expect(s.parseRetryAfter('2024-01-01T12:00:30Z'), const Duration(seconds: 30));
      expect(s.parseRetryAfter('2023-01-01T12:00:30Z'), Duration.zero);
    });
  });

  group('circuit breaker', () {
    test('opens after the threshold, doubles on repeated trips up to the cap, and resets on success', () {
      final clock = FixedClock(DateTime.utc(2024, 1, 1, 12));
      final s = RequestScheduler(clock: clock, circuitBase: const Duration(seconds: 60), circuitMax: const Duration(seconds: 200));
      s.recordRateLimited();
      expect(s.circuitOpen, isFalse);
      s.recordRateLimited(); // trip 1: 60 s
      expect(s.circuitOpen, isTrue);
      clock.value = clock.value.add(const Duration(seconds: 61));
      expect(s.circuitOpen, isFalse);
      s.recordRateLimited(); // trip 2: 120 s
      clock.value = clock.value.add(const Duration(seconds: 100));
      expect(s.circuitOpen, isTrue);
      clock.value = clock.value.add(const Duration(seconds: 21));
      expect(s.circuitOpen, isFalse);
      s.recordRateLimited(); // trip 3: capped at 200 s, not 240
      clock.value = clock.value.add(const Duration(seconds: 201));
      expect(s.circuitOpen, isFalse);
      s.recordRateLimited();
      expect(s.circuitOpen, isTrue);
      s.recordSuccess();
      expect(s.circuitOpen, isFalse);
      s.recordRateLimited();
      expect(s.circuitOpen, isFalse, reason: 'the counter restarted');
    });
  });
}

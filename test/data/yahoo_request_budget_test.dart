import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/market_data_repository_impl.dart';
import 'package:dashfolio/data/yahoo/yahoo_client.dart';
import 'package:dashfolio/data/yahoo/yahoo_config.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_http.dart';
import '../support/fixtures.dart';

/// Request-count regressions (SPEC §8A): a change that makes the app talk to Yahoo more often must fail here.
void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late FixedClock clock;
  late MarketDataRepositoryImpl repo;

  // Symbols present in the quote fixture, so every one of them lands in the cache.
  const held = ['AAPL', 'VOD.L', 'EURUSD=X', 'BTC-USD'];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime.utc(2024, 1, 10, 12));
    adapter = FakeAdapter((o) {
      if (o.uri.path.startsWith('/v8/finance/chart')) return jsonBody(fixtureText('chart_equity.json'));
      if (o.uri.path == '/v7/finance/quote') return jsonBody(fixtureText('quote_batch.json'));
      return jsonBody('{}', 404);
    });
    // Proxy mode: no crumb or cookie traffic, so every counted request is a data request.
    final client = YahooClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: const YahooConfig(proxyBase: 'https://proxy.example.com'),
      backoff: (_) async {},
      clock: clock,
    );
    repo = MarketDataRepositoryImpl(db, client, clock);
  });
  tearDown(() => db.close());

  int quoteCalls() => adapter.where('GET', '/v7/finance/quote').length;
  int chartCalls() => adapter.requests.where((r) => r.uri.path.startsWith('/v8/finance/chart')).length;

  group('quotes', () {
    test('cold start: all symbols in a single batched request', () async {
      await repo.refreshQuotes(held);
      expect(quoteCalls(), 1);
      expect(adapter.requests.single.queryParameters['symbols'], held.join(','));
    });

    test('warm refresh with nothing stale makes no request', () async {
      await repo.refreshQuotes(held);
      adapter.requests.clear();
      clock.value = clock.value.add(const Duration(seconds: 10));
      final r = await repo.refreshQuotes(held);
      expect(adapter.requests, isEmpty);
      expect(r.valueOrNull?.fetched, held.length);
    });

    test('once the TTL has passed the symbols are requested again, still in one batch', () async {
      await repo.refreshQuotes(held);
      adapter.requests.clear();
      clock.value = clock.value.add(MarketDataRepositoryImpl.quoteTtl + const Duration(seconds: 1));
      await repo.refreshQuotes(held);
      expect(quoteCalls(), 1);
    });

    test('only the stale or missing symbols are requested', () async {
      await repo.refreshQuotes(['AAPL']);
      adapter.requests.clear();
      await repo.refreshQuotes(['AAPL', 'NEWSYM']); // AAPL is fresh; NEWSYM was never fetched
      expect(adapter.requests.single.queryParameters['symbols'], 'NEWSYM');
    });

    test('force bypasses the TTL', () async {
      await repo.refreshQuotes(held);
      adapter.requests.clear();
      await repo.refreshQuotes(held, force: true);
      expect(quoteCalls(), 1);
    });

    test('more than 50 symbols are chunked into batches of 50', () async {
      final many = [for (var i = 0; i < 120; i++) 'SYM$i'];
      await repo.refreshQuotes(many);
      expect(quoteCalls(), 3);
    });
  });

  group('daily history', () {
    final from = DateTime.utc(2023, 12, 1);

    test('first load makes one request; repeats inside the TTL make none', () async {
      await repo.dailyHistory('AAPL', from);
      expect(chartCalls(), 1);
      clock.value = clock.value.add(const Duration(hours: 5));
      await repo.dailyHistory('AAPL', from);
      expect(chartCalls(), 1);
    });

    test('after the TTL the refresh is one incremental request, not a refetch of the whole range', () async {
      await repo.dailyHistory('AAPL', from);
      adapter.requests.clear();
      clock.value = clock.value.add(MarketDataRepositoryImpl.dailyTtl + const Duration(minutes: 1));
      await repo.dailyHistory('AAPL', from);
      expect(chartCalls(), 1);
      final period1 = int.parse(adapter.requests.single.queryParameters['period1'] as String);
      expect(period1, greaterThan(from.millisecondsSinceEpoch ~/ 1000 + 7 * 86400), reason: 'starts near the newest cached candle');
    });

    test('concurrent requests for one symbol share a single call', () async {
      await Future.wait([repo.dailyHistory('AAPL', from), repo.dailyHistory('AAPL', from)]);
      expect(chartCalls(), 1);
    });
  });
}

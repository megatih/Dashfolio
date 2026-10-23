import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/core/result.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/market_data_repository_impl.dart';
import 'package:dashfolio/data/yahoo/crumb_manager.dart';
import 'package:dashfolio/data/yahoo/yahoo_client.dart';
import 'package:dashfolio/data/yahoo/yahoo_config.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixtures.dart';
import 'yahoo/yahoo_client_test.dart' show FakeAdapter, body;

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late FixedClock clock;
  late MarketDataRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime.utc(2024, 1, 10, 12));
    adapter = FakeAdapter((o) {
      if (o.uri.host == 'fc.yahoo.com') return body('', 404);
      if (o.uri.path == '/v1/test/getcrumb') return body('crumb', 200);
      if (o.uri.path.startsWith('/v8/finance/chart')) return body(fixtureText('chart_equity.json'), 200);
      if (o.uri.path == '/v7/finance/quote') return body(fixtureText('quote_batch.json'), 200);
      if (o.uri.path == '/v1/finance/search') return body(fixtureText('search.json'), 200);
      if (o.uri.path.startsWith('/v10/finance/quoteSummary')) return body(fixtureText('quote_summary.json'), 200);
      return body('{}', 404);
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final client = YahooClient(dio: dio, config: const YahooConfig(), crumbManager: CrumbManager(dio), backoff: (_) async {}, clock: clock);
    repo = MarketDataRepositoryImpl(db, client, clock);
  });
  tearDown(() => db.close());

  int chartCalls() => adapter.requests.where((r) => r.uri.path.startsWith('/v8/finance/chart')).length;

  test('refreshQuotes caches quotes and exposes them via watchQuotes', () async {
    // Quote endpoint requires a crumb on native; the fake client has no CrumbManager so call goes without.
    final r = await repo.refreshQuotes(['AAPL', 'VOD.L']);
    final refresh = (r as Ok).value;
    expect(refresh.requested, 2);
    expect(refresh.fetched, 5); // all rows in the fixture are cached (superset of the request)
    final quotes = await repo.watchQuotes().first;
    expect(quotes['AAPL']!.price, 190.5);
    expect(quotes['VOD.L']!.currency, 'GBP');
    expect(quotes['VOD.L']!.price, closeTo(0.725, 1e-9));
  });

  test('refreshQuotes with no symbols is a no-op', () async {
    final r = await repo.refreshQuotes([]);
    expect((r as Ok).value.fetched, 0);
    expect(adapter.requests, isEmpty);
  });

  test('refreshQuotes returns the failure when nothing could be fetched', () async {
    adapter.handler = (o) => body('nope', 429);
    final r = await repo.refreshQuotes(['AAPL']);
    expect((r as Err).failure, isA<RateLimitedFailure>());
  });

  test('dailyHistory fetches once, then serves fresh cache without network', () async {
    final first = await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    final h = (first as Ok).value;
    expect(h.candles.length, 4);
    expect(h.dividends.single.amount, 0.24);
    expect(h.splits.single.numerator, 4);
    expect(chartCalls(), 1);

    final again = await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    expect((again as Ok).value.candles.length, 4);
    expect(chartCalls(), 1);
  });

  test('dailyHistory refetches incrementally once the cache is stale', () async {
    await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    clock.value = clock.value.add(const Duration(hours: 7));
    await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    expect(chartCalls(), 2);
    final calls = adapter.requests.where((r) => r.uri.path.startsWith('/v8/finance/chart')).toList();
    // period1 resumes from the newest cached candle (minus overlap), not from the original start.
    final p1 = int.parse(calls.first.queryParameters['period1'] as String);
    final p2 = int.parse(calls.last.queryParameters['period1'] as String);
    expect(p2, greaterThan(p1));
  });

  test('dailyHistory falls back to cached candles when the network fails', () async {
    await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    clock.value = clock.value.add(const Duration(days: 2));
    adapter.handler = (o) => body('down', 503);
    final r = await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    expect((r as Ok).value.candles, isNotEmpty);
  });

  test('dailyHistory without cache surfaces the failure', () async {
    adapter.handler = (o) => body('down', 503);
    final r = await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    expect(r is Err<PriceHistory>, isTrue);
  });

  test('chartHistory caches by interval and honours force', () async {
    await repo.chartHistory('AAPL', ChartRange.m1);
    await repo.chartHistory('AAPL', ChartRange.m1);
    expect(chartCalls(), 1);
    await repo.chartHistory('AAPL', ChartRange.m1, force: true);
    expect(chartCalls(), 2);
  });

  test('search passes through and blank queries skip the network', () async {
    final r = await repo.search('apple');
    expect((r as Ok).value.results.first.symbol, 'AAPL');
    final blank = await repo.search('   ');
    expect((blank as Ok).value.results, isEmpty);
    expect(adapter.requests.where((r) => r.uri.path == '/v1/finance/search').length, 1);
  });

  test('profile is cached, and enriches the cached quote with sector and beta', () async {
    await repo.refreshQuotes(['AAPL']);
    final p = (await repo.profile('AAPL') as Ok).value;
    expect(p.sector, 'Technology');
    final q = (await repo.watchQuotes().first)['AAPL']!;
    expect(q.sector, 'Technology');
    expect(q.beta, 1.29);

    await repo.profile('AAPL');
    expect(adapter.requests.where((r) => r.uri.path.startsWith('/v10/')).length, 1);

    // A later quote refresh keeps the enrichment.
    await repo.refreshQuotes(['AAPL']);
    expect((await repo.watchQuotes().first)['AAPL']!.sector, 'Technology');
  });

  test('clearCache empties caches', () async {
    await repo.refreshQuotes(['AAPL']);
    await repo.dailyHistory('AAPL', DateTime.utc(2024, 1, 1));
    await repo.clearCache();
    expect(await repo.watchQuotes().first, isEmpty);
    expect(await repo.cachedDaily('AAPL', DateTime.utc(2000)), isEmpty);
    expect(await repo.watchDividendEvents().first, isEmpty);
  });
}

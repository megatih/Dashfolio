import 'dart:convert';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/core/result.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:dashfolio/data/repositories/luno_market_data_repository.dart';
import 'package:dashfolio/data/repositories/routing_market_data_repository.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dashfolio/domain/repositories/market_data_repository.dart' show QuoteRefresh;
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http.dart';
import '../../support/fake_market_data.dart';
import '../../support/luno_fixtures.dart';

void main() {
  late AppDatabase db;
  late FakeAdapter adapter;
  late FixedClock clock;
  late FakeMarketData yahoo;
  late LunoMarketDataRepository repo;
  var withKey = true;
  var tickerStatus = 200;

  /// Daily candles from [since] (floored to the day) up to 2024-06-01, at most 1000, like the real endpoint.
  ResponseBody candles(RequestOptions o) {
    final duration = int.parse(o.queryParameters['duration'] as String);
    final since = int.parse(o.queryParameters['since'] as String);
    final step = duration * 1000;
    final end = DateTime.utc(2024, 6, 1).millisecondsSinceEpoch;
    var t = (since + step - 1) ~/ step * step;
    final list = <Map<String, Object?>>[];
    while (t <= end && list.length < 1000) {
      final i = t ~/ step;
      list.add({
        'timestamp': t,
        'open': '${250000 + i % 50}',
        'high': '${251000 + i % 50}',
        'low': '${249000 + i % 50}',
        'close': '${250500 + i % 50}',
        'volume': '1.5',
      });
      t += step;
    }
    return jsonBody(jsonEncode({'duration': duration, 'pair': o.queryParameters['pair'], 'candles': list}));
  }

  setUp(() {
    withKey = true;
    tickerStatus = 200;
    db = AppDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime.utc(2024, 6, 1, 12));
    yahoo = FakeMarketData()..daily['BTC-MYR'] = fakeCandles('2024-01-01', List.generate(200, (i) => 280000.0 + i));
    adapter = FakeAdapter((o) {
      switch (o.uri.path) {
        case '/api/1/tickers':
          return tickerStatus == 200 ? jsonBody(lunoFixtureText('tickers.json')) : jsonBody('{}', tickerStatus);
        case '/api/exchange/1/markets':
          return jsonBody(lunoFixtureText('markets.json'));
        case '/api/exchange/1/candles':
          return candles(o);
        case '/api/1/fee_info':
          return jsonBody(lunoFixtureText('fee_info.json'));
      }
      return jsonBody('{}', 404);
    });
    final client = LunoClient(
      dio: Dio()..httpClientAdapter = adapter,
      credentials: () async => withKey ? const LunoCredentials(keyId: 'k', keySecret: 's') : throw const CredentialsMissingFailure(),
      maxAttempts: 1,
      backoff: (_) async {},
      scheduler: RequestScheduler(),
    );
    repo = LunoMarketDataRepository(db, client, yahoo, clock);
  });
  tearDown(() => db.close());

  int calls(String path) => adapter.requests.where((r) => r.uri.path == path).length;

  Future<Quote> quote(String symbol) async => (await db.select(db.quoteCache).get())
      .map((r) => Quote.fromJson((jsonDecode(r.payloadJson) as Map).cast()))
      .firstWhere((q) => q.symbol == symbol);

  group('quotes', () {
    test('one ticker request for all symbols, mapped to cached quotes', () async {
      final r = await repo.refreshQuotes(['LUNO:XBTMYR', 'LUNO:ETHMYR', 'LUNO:ETHXBT']);
      expect((r as Ok<QuoteRefresh>).value.fetched, 3);
      expect(calls('/api/1/tickers'), 1);
      expect(adapter.requests.firstWhere((q) => q.uri.path == '/api/1/tickers').uri.query, contains('pair=XBTMYR&pair=ETHMYR&pair=ETHXBT'));

      final btc = await quote('LUNO:XBTMYR');
      expect((btc.name, btc.price, btc.bid, btc.ask, btc.volume), ('Bitcoin', 300000.0, 299900.0, 300100.0, 12.345678));
      expect((btc.currency, btc.quoteType, btc.exchange, btc.marketState), ('MYR', 'CRYPTOCURRENCY', 'Luno', 'REGULAR'));
      expect((await quote('LUNO:ETHXBT')).marketState, 'POSTONLY');
      expect((await quote('LUNO:ETHXBT')).currency, 'XBT');
    });

    test('fresh quotes are not requested again; stale or forced ones are', () async {
      await repo.refreshQuotes(['LUNO:XBTMYR']);
      adapter.requests.clear();
      clock.value = clock.value.add(const Duration(seconds: 10));
      await repo.refreshQuotes(['LUNO:XBTMYR']);
      expect(adapter.requests, isEmpty);
      clock.value = clock.value.add(LunoMarketDataRepository.quoteTtl);
      await repo.refreshQuotes(['LUNO:XBTMYR']);
      expect(calls('/api/1/tickers'), 1);
      await repo.refreshQuotes(['LUNO:XBTMYR'], force: true);
      expect(calls('/api/1/tickers'), 2);
    });

    test('a long symbol list uses one unfiltered ticker request instead of a huge query string', () async {
      await repo.refreshQuotes([for (var i = 0; i < 40; i++) 'LUNO:AAA${i}MYR', 'LUNO:XBTMYR']);
      final req = adapter.requests.firstWhere((q) => q.uri.path == '/api/1/tickers');
      expect(req.uri.query, isEmpty);
      expect(calls('/api/1/tickers'), 1);
      expect((await quote('LUNO:XBTMYR')).price, 300000.0);
    });

    test('markets the exchange does not know are reported as partial, the rest are stored', () async {
      final r = (await repo.refreshQuotes(['LUNO:XBTMYR', 'LUNO:NOPEMYR'])) as Ok<QuoteRefresh>;
      expect((r.value.fetched, r.value.requested, r.value.partial), (1, 2, true));
      expect(r.value.failures.single, isA<NotFoundFailure>());
    });

    test('an unavailable API is an error and leaves the cache alone', () async {
      await repo.refreshQuotes(['LUNO:XBTMYR']);
      tickerStatus = 503;
      clock.value = clock.value.add(const Duration(minutes: 5));
      final r = await repo.refreshQuotes(['LUNO:XBTMYR']);
      expect(r, isA<Err<QuoteRefresh>>());
      expect((await quote('LUNO:XBTMYR')).price, 300000.0);
    });

    test('non-Luno symbols are ignored', () async {
      final r = (await repo.refreshQuotes(['AAPL'])) as Ok<QuoteRefresh>;
      expect(r.value.requested, 0);
      expect(adapter.requests, isEmpty);
    });

    test('previous close and the day range come from the cached daily candles, in UTC days', () async {
      await repo.refreshQuotes(['LUNO:XBTMYR']);
      expect((await quote('LUNO:XBTMYR')).previousClose, isNull);
      await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 5, 1));
      final q = await quote('LUNO:XBTMYR');
      final may31 = DateTime.utc(2024, 5, 31).millisecondsSinceEpoch ~/ 86400000;
      expect(q.previousClose, 250500.0 + may31 % 50);
      final jun1 = DateTime.utc(2024, 6, 1).millisecondsSinceEpoch ~/ 86400000;
      expect(q.open, 250000.0 + jun1 % 50);
      expect(q.dayHigh, 300000.0, reason: 'the live price is above the candle high');
      expect(q.changePct, isNotNull);
    });
  });

  group('history', () {
    test('daily history pages through the candle endpoint and caches the series under the daily key', () async {
      final r = (await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2021, 1, 1))) as Ok<PriceHistory>;
      expect(calls('/api/exchange/1/candles'), 2, reason: '~1250 daily candles need two pages of 1000');
      expect(r.value.candles.length, greaterThan(1200));
      expect(r.value.currency, 'MYR');
      expect(r.value.via, isNull);
      expect(adapter.requests.first.queryParameters['duration'], '86400');
      expect((await repo.cachedDaily('LUNO:XBTMYR', DateTime.utc(2024, 5, 30))).length, 3);
    });

    test('a repeat inside the TTL is free; after it the refresh is one incremental request', () async {
      await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 1, 1));
      adapter.requests.clear();
      clock.value = clock.value.add(const Duration(hours: 5));
      await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 1, 1));
      expect(adapter.requests, isEmpty);

      clock.value = clock.value.add(const Duration(hours: 2));
      await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 1, 1));
      expect(adapter.requests.length, 1);
      final since = int.parse(adapter.requests.single.queryParameters['since'] as String);
      expect(since, greaterThan(DateTime.utc(2024, 5, 20).millisecondsSinceEpoch), reason: 'starts a week before the newest cached candle');
    });

    test('chart ranges pick the candle duration and cache each resolution separately', () async {
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.d1);
      expect(adapter.requests.last.queryParameters['duration'], '300');
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.m1);
      expect(adapter.requests.last.queryParameters['duration'], '14400');
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.y1);
      expect(adapter.requests.last.queryParameters['duration'], '86400');
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.max);
      expect(adapter.requests.last.queryParameters['duration'], '604800');
      final n = adapter.requests.length;
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.m1);
      expect(adapter.requests.length, n, reason: 'served from cache');
    });

    test('the chart cache honours the intraday TTL', () async {
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.d1);
      final n = adapter.requests.length;
      clock.value = clock.value.add(const Duration(minutes: 1));
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.d1);
      expect(adapter.requests.length, n);
      clock.value = clock.value.add(const Duration(minutes: 2));
      await repo.chartHistory('LUNO:XBTMYR', ChartRange.d1);
      expect(adapter.requests.length, n + 1);
    });

    test('without an API key the matching Yahoo series is used and labelled', () async {
      withKey = false;
      final chart = (await repo.chartHistory('LUNO:XBTMYR', ChartRange.m3)) as Ok<PriceHistory>;
      expect((chart.value.via, chart.value.currency, chart.value.symbol), ('Yahoo', 'MYR', 'LUNO:XBTMYR'));
      expect(chart.value.candles, isNotEmpty);
      expect(adapter.requests, isEmpty, reason: 'no request is sent without credentials');

      // Valuation reads the same cache key, so the Yahoo series is adopted under the Luno symbol.
      final daily = (await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 2, 1))) as Ok<PriceHistory>;
      expect(daily.value.candles, isNotEmpty);
      expect((await repo.cachedDaily('LUNO:XBTMYR', DateTime.utc(2024, 2, 1))).first.close, greaterThan(280000));
    });

    test('when neither Luno nor the fallback has data the failure surfaces', () async {
      withKey = false;
      yahoo.daily.clear();
      expect(await repo.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 2, 1)), isA<Err<PriceHistory>>());
    });

    test('yahooEquivalent maps Luno codes to Yahoo codes', () {
      expect(LunoMarketDataRepository.yahooEquivalent('LUNO:XBTMYR'), 'BTC-MYR');
      expect(LunoMarketDataRepository.yahooEquivalent('LUNO:ETHZAR'), 'ETH-ZAR');
    });
  });

  group('markets, search and fees', () {
    Future<List<String>> found(String q) async =>
        ((await repo.search(q)) as Ok<SearchResponse>).value.results.map((r) => r.symbol).toList();

    test('search matches pair codes, asset names and Yahoo-style codes', () async {
      expect(await found('bitcoin'), ['LUNO:XBTMYR']);
      expect(await found('btc'), ['LUNO:XBTMYR']);
      expect(await found('XBT'), ['LUNO:XBTMYR', 'LUNO:ETHXBT']);
      expect(await found('myr'), ['LUNO:XBTMYR', 'LUNO:ETHMYR']);
      expect(await found('ethereum'), ['LUNO:ETHMYR', 'LUNO:ETHXBT']);
      expect(await found('zzz'), isEmpty);
      expect(await found('  '), isEmpty);
      final r = ((await repo.search('bitcoin')) as Ok<SearchResponse>).value.results.single;
      expect((r.name, r.exchange, r.quoteType), ('Bitcoin / MYR', 'Luno', 'CRYPTOCURRENCY'));
    });

    test('market parameters are fetched once a day', () async {
      await repo.search('btc');
      await repo.search('eth');
      expect(calls('/api/exchange/1/markets'), 1);
      clock.value = clock.value.add(const Duration(hours: 25));
      await repo.search('eth');
      expect(calls('/api/exchange/1/markets'), 2);
    });

    test('the cached markets keep working when the refresh fails', () async {
      await repo.search('btc');
      clock.value = clock.value.add(const Duration(hours: 25));
      adapter.handler = (o) => jsonBody('{}', 503);
      expect(await found('btc'), ['LUNO:XBTMYR']);
    });

    test('fee info is fetched lazily and cached for a day', () async {
      final a = (await repo.feeInfo('LUNO:XBTMYR')) as Ok;
      await repo.feeInfo('LUNO:XBTMYR');
      expect(calls('/api/1/fee_info'), 1);
      expect(a.value.takerFeeBuy.toString(), '0.001');
    });

    test('clearCache forgets the cached markets', () async {
      await repo.search('btc');
      await repo.clearCache();
      expect(await db.select(db.lunoMarketsCache).get(), isEmpty);
    });

    test('the profile is a plain description', () async {
      final p = (await repo.profile('LUNO:XBTMYR')) as Ok<AssetProfile>;
      expect(p.value.description, contains('Bitcoin'));
    });
  });

  group('routing', () {
    late RoutingMarketDataRepository router;
    setUp(() => router = RoutingMarketDataRepository(primary: yahoo, luno: repo));

    test('quotes: each provider gets only its own symbols, in parallel', () async {
      yahoo.setQuote(fakeQuote('AAPL'));
      final r = (await router.refreshQuotes(['AAPL', 'LUNO:XBTMYR'])) as Ok<QuoteRefresh>;
      expect(yahoo.refreshCalls.single, {'AAPL'});
      expect(calls('/api/1/tickers'), 1);
      expect((r.value.fetched, r.value.requested), (2, 2));
    });

    test('quotes: only-Yahoo and only-Luno requests touch just one provider', () async {
      await router.refreshQuotes(['AAPL']);
      expect(adapter.requests, isEmpty);
      await router.refreshQuotes(['LUNO:XBTMYR']);
      expect(yahoo.refreshCalls.length, 1);
    });

    test('quotes: one provider failing makes the refresh partial, both failing makes it an error', () async {
      yahoo.refreshFailure = const NetworkFailure();
      final partial = (await router.refreshQuotes(['AAPL', 'LUNO:XBTMYR'])) as Ok<QuoteRefresh>;
      expect((partial.value.fetched, partial.value.requested, partial.value.partial), (1, 2, true));

      tickerStatus = 503;
      clock.value = clock.value.add(const Duration(minutes: 5));
      expect(await router.refreshQuotes(['AAPL', 'LUNO:XBTMYR']), isA<Err<QuoteRefresh>>());
    });

    test('history and profiles are routed by symbol', () async {
      yahoo.daily['AAPL'] = fakeCandles('2024-05-01', [1, 2, 3]);
      final a = (await router.dailyHistory('AAPL', DateTime.utc(2024, 5, 1))) as Ok<PriceHistory>;
      expect(a.value.candles.length, 3);
      expect(adapter.requests, isEmpty);
      final l = (await router.dailyHistory('LUNO:XBTMYR', DateTime.utc(2024, 5, 20))) as Ok<PriceHistory>;
      expect(l.value.symbol, 'LUNO:XBTMYR');
      expect((await router.chartHistory('LUNO:XBTMYR', ChartRange.d5)), isA<Ok<PriceHistory>>());
      expect(await router.profile('LUNO:XBTMYR'), isA<Ok<AssetProfile>>());
    });

    test('search merges both providers and survives Yahoo being unreachable', () async {
      yahoo.searchResponse = const SearchResponse(
        results: [SearchResult(symbol: 'BTC-USD', name: 'Bitcoin USD', quoteType: 'CRYPTOCURRENCY')],
        news: [],
      );
      final both = ((await router.search('bitcoin')) as Ok<SearchResponse>).value.results.map((r) => r.symbol).toList();
      expect(both, ['BTC-USD', 'LUNO:XBTMYR']);
    });

    test('clearCache clears every provider', () async {
      await repo.search('btc');
      yahoo.setQuote(fakeQuote('AAPL'));
      await router.clearCache();
      expect(yahoo.quotes, isEmpty);
      expect(await db.select(db.lunoMarketsCache).get(), isEmpty);
    });
  });
}

import 'dart:async';

import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/core/result.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dashfolio/domain/repositories/market_data_repository.dart';

/// In-memory [MarketDataRepository] for tests: quotes and daily series are set directly.
class FakeMarketData implements MarketDataRepository {
  FakeMarketData({Map<String, Quote>? quotes}) : quotes = {...?quotes};

  final Map<String, Quote> quotes;
  final Map<String, List<Candle>> daily = {};
  final Map<String, List<DividendEvent>> dividends = {};
  final Map<String, List<SplitEvent>> splits = {};
  SearchResponse searchResponse = const SearchResponse(results: [], news: []);
  AppFailure? refreshFailure;
  final List<Set<String>> refreshCalls = [];
  final _quotes = StreamController<Map<String, Quote>>.broadcast();

  void setQuote(Quote q) {
    quotes[q.symbol] = q;
    _quotes.add({...quotes});
  }

  @override
  Stream<Map<String, Quote>> watchQuotes() async* {
    yield {...quotes};
    yield* _quotes.stream;
  }

  @override
  Future<Map<String, Quote>> quotesSnapshot() async => {...quotes};

  @override
  Future<Result<QuoteRefresh>> refreshQuotes(Iterable<String> symbols, {bool force = false}) async {
    refreshCalls.add(symbols.toSet());
    if (refreshFailure != null) return Result.err(refreshFailure!);
    return Result.ok(QuoteRefresh(fetched: symbols.where(quotes.containsKey).length, requested: symbols.length));
  }

  @override
  Future<Result<PriceHistory>> chartHistory(String symbol, ChartRange range, {bool force = false}) async {
    final c = daily[symbol];
    return c == null ? const Result.err(NotFoundFailure()) : Result.ok(PriceHistory(symbol: symbol, candles: c));
  }

  @override
  Future<Result<PriceHistory>> dailyHistory(String symbol, DateTime from, {bool force = false}) async {
    final c = daily[symbol];
    if (c == null) return const Result.err(NotFoundFailure());
    return Result.ok(
      PriceHistory(
        symbol: symbol,
        candles: c.where((x) => !x.time.isBefore(from)).toList(),
        dividends: dividends[symbol] ?? const [],
        splits: splits[symbol] ?? const [],
      ),
    );
  }

  @override
  Future<List<Candle>> cachedDaily(String symbol, DateTime from) async => daily[symbol] ?? const [];

  @override
  Future<Result<SearchResponse>> search(String query) async => Result.ok(searchResponse);

  @override
  Future<Result<AssetProfile>> profile(String symbol, {bool force = false}) async => const Result.err(NotFoundFailure());

  @override
  Stream<Map<String, List<DividendEvent>>> watchDividendEvents() => Stream.value(dividends);

  @override
  Stream<Map<String, List<SplitEvent>>> watchSplitEvents() => Stream.value(splits);

  @override
  Future<void> clearCache() async {
    quotes.clear();
    daily.clear();
  }
}

Quote fakeQuote(
  String symbol, {
  double price = 100,
  double? prev,
  String currency = 'USD',
  String type = 'EQUITY',
  String? name,
  String? sector,
}) => Quote(
  symbol: symbol,
  name: name ?? symbol,
  price: price,
  previousClose: prev ?? price,
  currency: currency,
  quoteType: type,
  sector: sector,
  fetchedAt: DateTime.utc(2024, 6, 1),
);

List<Candle> fakeCandles(String start, List<double> closes) {
  final s = DateTime.parse('${start}T00:00:00Z');
  return [
    for (var i = 0; i < closes.length; i++)
      Candle(
        time: s.add(Duration(days: i)),
        open: closes[i],
        high: closes[i],
        low: closes[i],
        close: closes[i],
      ),
  ];
}

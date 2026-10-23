import '../../core/failure.dart';
import '../../core/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_data_repository.dart';
import 'luno_market_data_repository.dart';

/// Sends `LUNO:` symbols to Luno and everything else to the primary provider (Yahoo). All providers write the same
/// caches, so quote streams, snapshots and cached history come from the primary repository unchanged.
class RoutingMarketDataRepository implements MarketDataRepository {
  RoutingMarketDataRepository({required this.primary, required this.luno});

  final MarketDataRepository primary;
  final LunoMarketDataRepository luno;

  @override
  Stream<Map<String, Quote>> watchQuotes() => primary.watchQuotes();

  @override
  Future<Map<String, Quote>> quotesSnapshot() => primary.quotesSnapshot();

  @override
  Future<Result<QuoteRefresh>> refreshQuotes(Iterable<String> symbols, {bool force = false}) async {
    final all = symbols.toSet();
    final lunoSymbols = all.where(isLunoSymbol).toList();
    final other = all.where((s) => !isLunoSymbol(s)).toList();
    if (lunoSymbols.isEmpty) return primary.refreshQuotes(other, force: force);
    if (other.isEmpty) return luno.refreshQuotes(lunoSymbols, force: force);

    // Independent providers: one being down must not hold back the other.
    final results = await Future.wait([primary.refreshQuotes(other, force: force), luno.refreshQuotes(lunoSymbols, force: force)]);
    var fetched = 0, requested = 0;
    final failures = <AppFailure>[];
    for (final r in results) {
      switch (r) {
        case Ok(:final value):
          fetched += value.fetched;
          requested += value.requested;
          failures.addAll(value.failures);
        case Err(:final failure):
          failures.add(failure);
      }
    }
    final okCount = results.whereType<Ok<QuoteRefresh>>().length;
    if (okCount == 0) return Result.err(failures.first);
    // A provider that failed outright still counts its symbols as requested, so the refresh reads as partial.
    final failedRequested = [if (results[0] is Err) other.length, if (results[1] is Err) lunoSymbols.length].fold(0, (a, b) => a + b);
    return Result.ok(QuoteRefresh(fetched: fetched, requested: requested + failedRequested, failures: failures));
  }

  @override
  Future<Result<PriceHistory>> chartHistory(String symbol, ChartRange range, {bool force = false}) =>
      isLunoSymbol(symbol) ? luno.chartHistory(symbol, range, force: force) : primary.chartHistory(symbol, range, force: force);

  @override
  Future<Result<PriceHistory>> dailyHistory(String symbol, DateTime from, {bool force = false}) =>
      isLunoSymbol(symbol) ? luno.dailyHistory(symbol, from, force: force) : primary.dailyHistory(symbol, from, force: force);

  @override
  Future<List<Candle>> cachedDaily(String symbol, DateTime from) => primary.cachedDaily(symbol, from);

  @override
  Future<Result<SearchResponse>> search(String query) async {
    final results = await Future.wait([primary.search(query), luno.search(query)]);
    final a = results[0], b = results[1];
    if (a is Ok<SearchResponse> && b is Ok<SearchResponse>) {
      return Result.ok(SearchResponse(results: [...a.value.results, ...b.value.results], news: a.value.news));
    }
    if (a is Ok<SearchResponse>) return a;
    if (b is Ok<SearchResponse>) return b; // Yahoo unreachable: Luno pairs are still searchable
    return a;
  }

  @override
  Future<Result<AssetProfile>> profile(String symbol, {bool force = false}) =>
      isLunoSymbol(symbol) ? luno.profile(symbol) : primary.profile(symbol, force: force);

  @override
  Stream<Map<String, List<DividendEvent>>> watchDividendEvents() => primary.watchDividendEvents();

  @override
  Stream<Map<String, List<SplitEvent>>> watchSplitEvents() => primary.watchSplitEvents();

  @override
  Future<void> clearCache() async {
    await primary.clearCache();
    await luno.clearCache();
  }
}

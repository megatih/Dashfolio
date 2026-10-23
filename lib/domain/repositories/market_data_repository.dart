import '../../core/failure.dart';
import '../../core/result.dart';
import '../entities/enums.dart';
import '../entities/market.dart';

class QuoteRefresh {
  const QuoteRefresh({required this.fetched, required this.requested, this.failures = const []});
  final int fetched;
  final int requested;
  final List<AppFailure> failures;
  bool get partial => failures.isNotEmpty;
}

/// Source of market data. Implemented over Yahoo Finance plus local caches;
/// a different provider only needs to implement this interface.
abstract class MarketDataRepository {
  /// Cached quotes keyed by symbol; emits whenever the cache changes.
  Stream<Map<String, Quote>> watchQuotes();

  /// One-shot snapshot of the quote cache.
  Future<Map<String, Quote>> quotesSnapshot();

  /// Fetches fresh quotes for [symbols] and writes them to the cache. Symbols whose cached quote is younger than the
  /// provider's quote TTL are not requested again unless [force] is set.
  Future<Result<QuoteRefresh>> refreshQuotes(Iterable<String> symbols, {bool force = false});

  /// Candles for an interactive chart range (cached with a TTL).
  Future<Result<PriceHistory>> chartHistory(String symbol, ChartRange range, {bool force = false});

  /// Daily candles from [from] until today, fetched incrementally and cached.
  Future<Result<PriceHistory>> dailyHistory(String symbol, DateTime from, {bool force = false});

  Future<Result<SearchResponse>> search(String query);

  Future<Result<AssetProfile>> profile(String symbol, {bool force = false});

  Stream<Map<String, List<DividendEvent>>> watchDividendEvents();
  Stream<Map<String, List<SplitEvent>>> watchSplitEvents();

  /// Cached daily closes for a symbol (used to build historical valuation series).
  Future<List<Candle>> cachedDaily(String symbol, DateTime from);

  Future<void> clearCache();
}

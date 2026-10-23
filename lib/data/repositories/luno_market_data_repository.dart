import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../db/app_database.dart';
import '../luno/luno_client.dart';
import 'price_cache.dart';

final _log = Logger('LunoMarketData');

/// Market data for `LUNO:{PAIR}` symbols, written to the same caches as every other provider.
///
/// Tickers and market parameters are public; candles require an API key, so without a Luno connection (or if the key
/// lacks access) history falls back to the matching Yahoo series (`XBTMYR` → `BTC-MYR`) and is labelled `via Yahoo`.
class LunoMarketDataRepository {
  LunoMarketDataRepository(this._db, this._client, this._fallback, [this._clock = const SystemClock()]);

  final AppDatabase _db;
  final LunoClient _client;

  /// Provider used when Luno cannot serve candles (the Yahoo repository).
  final MarketDataRepository _fallback;
  final Clock _clock;

  late final PriceCache _cache = PriceCache(_db, _clock);

  static const quoteTtl = Duration(seconds: 30);
  static const intradayTtl = Duration(minutes: 2);
  static const dailyTtl = Duration(hours: 6);
  static const marketsTtl = Duration(hours: 24);
  static const feeTtl = Duration(hours: 24);

  /// Beyond this many symbols one unfiltered ticker request is cheaper than a very long query string.
  static const tickerFilterLimit = 25;

  static const dailyInterval = '1d';

  /// Candle duration (seconds) serving each chart range.
  static int durationFor(ChartRange r) => switch (r) {
    ChartRange.d1 => 300,
    ChartRange.d5 => 1800,
    ChartRange.m1 => 14400,
    ChartRange.m3 || ChartRange.m6 || ChartRange.ytd || ChartRange.y1 => 86400,
    ChartRange.y5 || ChartRange.max => 604800,
  };

  /// Cache key of a candle series; daily candles share the key every provider uses for valuation.
  static String intervalKey(int duration) => duration == 86400 ? dailyInterval : 'luno-${duration}s';

  /// The Yahoo series standing in for a Luno pair, e.g. `LUNO:XBTMYR` → `BTC-MYR`.
  static String yahooEquivalent(String symbol) {
    final pair = lunoPairOf(symbol);
    final counter = pair.substring(pair.length - 3);
    return '${yahooAssetCode(pair.substring(0, pair.length - 3))}-$counter';
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Result.ok(await body());
    } on AppFailure catch (f) {
      return Result.err(f);
    } on DriftWrappedException catch (e) {
      _log.severe('Database error', e);
      return const Result.err(StorageFailure());
    }
  }

  // ---- markets -------------------------------------------------------------

  LunoMarket _market(LunoMarketRow r) => LunoMarket(
    pair: r.pair,
    base: r.base,
    counter: r.counter,
    priceScale: r.priceScale,
    volumeScale: r.volumeScale,
    status: LunoMarketStatus.parse(r.tradingStatus),
  );

  Future<List<LunoMarket>> _cachedMarkets() async => (await _db.select(_db.lunoMarketsCache).get()).map(_market).toList();

  /// Market parameters, cached for a day. A failed refresh falls back to the cache.
  Future<Result<List<LunoMarket>>> markets({bool force = false}) => _guard(() async {
    final rows = await _db.select(_db.lunoMarketsCache).get();
    final now = _clock.now();
    final fresh = rows.isNotEmpty && now.difference(rows.first.fetchedAt) < marketsTtl;
    if (fresh && !force) return rows.map(_market).toList();
    try {
      final fetched = await _client.markets();
      if (fetched.isEmpty) return rows.map(_market).toList();
      await _db.transaction(() async {
        await _db.delete(_db.lunoMarketsCache).go();
        await _db.batch((b) {
          b.insertAll(_db.lunoMarketsCache, [
            for (final m in fetched)
              LunoMarketsCacheCompanion.insert(
                pair: m.pair,
                base: m.base,
                counter: m.counter,
                priceScale: Value(m.priceScale),
                volumeScale: Value(m.volumeScale),
                tradingStatus: Value(m.status.name),
                fetchedAt: now,
              ),
          ]);
        });
      });
      return fetched;
    } on AppFailure {
      if (rows.isNotEmpty) return rows.map(_market).toList();
      rethrow;
    }
  });

  // ---- quotes --------------------------------------------------------------

  Quote _quoteFromTicker(LunoTicker t, LunoMarket? market, DateTime now, Quote? previous) {
    final base = market?.base ?? t.pair.substring(0, t.pair.length - 3);
    final counter = market?.counter ?? t.pair.substring(t.pair.length - 3);
    return Quote(
      symbol: lunoSymbol(t.pair),
      name: lunoAssetName(base),
      price: t.lastTrade?.toDouble(),
      // Day change and range come from the cached daily series (see _applyDaily); keep what we had until that is refreshed.
      previousClose: previous?.previousClose,
      open: previous?.open,
      dayHigh: previous?.dayHigh,
      dayLow: previous?.dayLow,
      volume: t.volume24h?.toDouble(),
      currency: counter,
      quoteType: 'CRYPTOCURRENCY',
      exchange: 'Luno',
      marketState: switch (t.status) {
        LunoMarketStatus.active => 'REGULAR',
        LunoMarketStatus.postOnly => 'POSTONLY',
        LunoMarketStatus.disabled => 'DISABLED',
        LunoMarketStatus.unknown => 'UNKNOWN',
      },
      bid: t.bid?.toDouble(),
      ask: t.ask?.toDouble(),
      fetchedAt: now,
    );
  }

  Quote? _decode(QuoteCacheRow? r) {
    if (r == null) return null;
    try {
      return Quote.fromJson((jsonDecode(r.payloadJson) as Map).cast<String, Object?>());
    } on Object {
      return null;
    }
  }

  /// Fetches tickers for the stale [symbols] in one request and writes them to `quote_cache`.
  Future<Result<QuoteRefresh>> refreshQuotes(Iterable<String> symbols, {bool force = false}) async {
    final requested = symbols.where(isLunoSymbol).toSet().toList();
    if (requested.isEmpty) return const Result.ok(QuoteRefresh(fetched: 0, requested: 0));

    final cached = {
      for (final r in await _db.select(_db.quoteCache).get())
        if (isLunoSymbol(r.symbol)) r.symbol: r,
    };
    final started = _clock.now();
    final stale = [
      for (final s in requested)
        if (force || cached[s] == null || started.difference(cached[s]!.fetchedAt) >= quoteTtl) s,
    ];
    if (stale.isEmpty) return Result.ok(QuoteRefresh(fetched: requested.length, requested: requested.length));

    try {
      final byPair = {for (final m in (await markets()).valueOrNull ?? const <LunoMarket>[]) m.pair: m};
      final pairs = [for (final s in stale) lunoPairOf(s)];
      final tickers = await _client.tickers(pairs.length > tickerFilterLimit ? const [] : pairs);
      final wanted = pairs.toSet();
      final now = _clock.now();
      final quotes = [
        for (final t in tickers)
          if (wanted.contains(t.pair)) _quoteFromTicker(t, byPair[t.pair], now, _decode(cached[lunoSymbol(t.pair)])),
      ];
      await _db.batch((b) {
        for (final q in quotes) {
          b.insert(
            _db.quoteCache,
            QuoteCacheCompanion.insert(symbol: q.symbol, payloadJson: jsonEncode(q.toJson()), fetchedAt: now),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      for (final q in quotes) {
        await _applyDaily(q.symbol);
      }
      final missing = wanted.length - quotes.length;
      return Result.ok(
        QuoteRefresh(
          fetched: requested.length - stale.length + quotes.length,
          requested: requested.length,
          failures: [if (missing > 0) NotFoundFailure('$missing Luno markets were not found')],
        ),
      );
    } on AppFailure catch (f) {
      return Result.err(f);
    } on DriftWrappedException catch (e) {
      _log.severe('Database error', e);
      return const Result.err(StorageFailure());
    }
  }

  /// Fills previous close, open and the day's range on the cached quote from the cached daily candles (UTC days).
  Future<void> _applyDaily(String symbol) async {
    final row = await (_db.select(_db.quoteCache)..where((t) => t.symbol.equals(symbol))).getSingleOrNull();
    final quote = _decode(row);
    if (row == null || quote == null) return;
    final now = _clock.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final candles = await _cache.readCandles(symbol, dailyInterval, from: today.subtract(const Duration(days: 10)));
    if (candles.isEmpty) return;
    final before = candles.where((c) => c.time.isBefore(today));
    final current = candles.where((c) => !c.time.isBefore(today)).firstOrNull;
    final merged = Quote(
      symbol: quote.symbol,
      name: quote.name,
      price: quote.price,
      previousClose: before.isEmpty ? quote.previousClose : before.last.close,
      open: current?.open ?? quote.open,
      dayHigh: current == null ? quote.dayHigh : (quote.price != null && quote.price! > current.high ? quote.price : current.high),
      dayLow: current == null ? quote.dayLow : (quote.price != null && quote.price! < current.low ? quote.price : current.low),
      volume: quote.volume,
      currency: quote.currency,
      quoteType: quote.quoteType,
      exchange: quote.exchange,
      marketState: quote.marketState,
      bid: quote.bid,
      ask: quote.ask,
      fetchedAt: quote.fetchedAt,
    );
    await (_db.update(
      _db.quoteCache,
    )..where((t) => t.symbol.equals(symbol))).write(QuoteCacheCompanion(payloadJson: Value(jsonEncode(merged.toJson()))));
  }

  // ---- history -------------------------------------------------------------

  Candle _candle(LunoCandle c) => Candle(
    time: c.timestamp,
    open: c.open.toDouble(),
    high: c.high.toDouble(),
    low: c.low.toDouble(),
    close: c.close.toDouble(),
    volume: c.volume.toDouble(),
  );

  /// Candles from [since] until now, paged 1000 at a time.
  Future<List<Candle>> _fetchCandles(String pair, DateTime since, int duration) async {
    final out = <Candle>[];
    var cursor = since;
    final now = _clock.now();
    while (true) {
      final page = await _client.candles(pair, since: cursor, duration: duration);
      out.addAll(page.map(_candle));
      if (page.length < LunoClient.pageSize) break;
      cursor = page.last.timestamp.add(Duration(seconds: duration));
      if (!cursor.isBefore(now)) break;
    }
    return out;
  }

  /// Failures after which Yahoo can still serve the series (no key, not permitted, unknown to the candles endpoint).
  static bool _fallbackWorthTrying(AppFailure f) =>
      f is CredentialsMissingFailure ||
      f is ForbiddenFailure ||
      f is KeyRevokedFailure ||
      f is NotFoundFailure ||
      f is SecureStorageUnavailableFailure;

  Future<Result<PriceHistory>> chartHistory(String symbol, ChartRange range, {bool force = false}) => _guard(() async {
    final pair = lunoPairOf(symbol);
    final duration = durationFor(range);
    final interval = intervalKey(duration);
    final now = _clock.now().toUtc();
    final start = range.start(now);
    final meta = await _cache.meta(symbol, interval);
    final ttl = range.intraday ? intradayTtl : dailyTtl;
    final fresh = meta != null && now.difference(meta.fetchedAt.toUtc()) < ttl;
    final covers = meta != null && (start == null || PriceCache.epoch(start) >= meta.oldestTs - duration);
    final counter = pair.substring(pair.length - 3);
    if (!force && fresh && covers) {
      final cached = await _cache.readCandles(symbol, interval, from: start);
      if (cached.isNotEmpty) return PriceHistory(symbol: symbol, candles: cached, currency: counter);
    }

    try {
      final candles = await _fetchCandles(pair, start ?? DateTime.utc(2013), duration);
      if (candles.isEmpty) throw const NotFoundFailure('No price data for this range');
      if (range.intraday || duration != 86400) await _cache.deleteSeries(symbol, interval);
      await _cache.storeCandles(symbol, interval, candles);
      final first = PriceCache.epoch(candles.first.time);
      final covered = start == null ? first : (PriceCache.epoch(start) < first ? PriceCache.epoch(start) : first);
      final prevOldest = meta?.oldestTs;
      await _cache.writeMeta(
        symbol,
        interval,
        range.intraday || duration != 86400 || prevOldest == null ? covered : (covered < prevOldest ? covered : prevOldest),
        PriceCache.epoch(candles.last.time),
        counter,
      );
      if (duration == 86400) await _applyDaily(symbol);
      return PriceHistory(symbol: symbol, candles: candles, currency: counter);
    } on AppFailure catch (f) {
      if (_fallbackWorthTrying(f)) {
        final via = await _fallback.chartHistory(yahooEquivalent(symbol), range, force: force);
        if (via case Ok(:final value)) {
          return PriceHistory(symbol: symbol, candles: value.candles, currency: counter, via: 'Yahoo');
        }
      }
      final cached = await _cache.readCandles(symbol, interval, from: start);
      if (cached.isNotEmpty) return PriceHistory(symbol: symbol, candles: cached, currency: counter);
      rethrow;
    }
  });

  Future<Result<PriceHistory>> dailyHistory(String symbol, DateTime from, {bool force = false}) => _guard(() async {
    final pair = lunoPairOf(symbol);
    final counter = pair.substring(pair.length - 3);
    final now = _clock.now().toUtc();
    final fromDay = DateTime.utc(from.year, from.month, from.day);
    final meta = await _cache.meta(symbol, dailyInterval);
    final hasHistory = meta != null && meta.oldestTs <= PriceCache.epoch(fromDay.add(const Duration(days: 5)));
    final fresh = meta != null && now.difference(meta.fetchedAt.toUtc()) < dailyTtl;

    Future<PriceHistory> cached() async => PriceHistory(
      symbol: symbol,
      candles: await _cache.readCandles(symbol, dailyInterval, from: fromDay),
      currency: counter,
    );

    if (hasHistory && fresh && !force) return cached();

    // Incremental: a week of overlap from the newest cached candle, else the whole requested window.
    final since = hasHistory ? PriceCache.fromEpoch(meta.newestTs - 7 * 86400) : fromDay.subtract(const Duration(days: 7));
    try {
      final candles = await _fetchCandles(pair, since, 86400);
      if (candles.isNotEmpty) await _cache.storeCandles(symbol, dailyInterval, candles);
      final oldest = candles.isEmpty ? (meta?.oldestTs ?? PriceCache.epoch(since)) : PriceCache.epoch(candles.first.time);
      final newest = candles.isEmpty ? (meta?.newestTs ?? PriceCache.epoch(since)) : PriceCache.epoch(candles.last.time);
      final requestedStart = PriceCache.epoch(since);
      await _cache.writeMeta(
        symbol,
        dailyInterval,
        hasHistory ? meta.oldestTs : (requestedStart < oldest ? requestedStart : oldest),
        hasHistory ? (newest > meta.newestTs ? newest : meta.newestTs) : newest,
        counter,
      );
    } on AppFailure catch (f) {
      if (_fallbackWorthTrying(f) && !hasHistory) {
        // No key (or no access): adopt the Yahoo series for this pair under the Luno symbol so valuation keeps working.
        final via = await _fallback.dailyHistory(yahooEquivalent(symbol), fromDay, force: force);
        if (via case Ok(:final value) when value.candles.isNotEmpty) {
          await _cache.storeCandles(symbol, dailyInterval, value.candles);
          await _cache.writeMeta(
            symbol,
            dailyInterval,
            PriceCache.epoch(fromDay.isBefore(value.candles.first.time) ? fromDay : value.candles.first.time),
            PriceCache.epoch(value.candles.last.time),
            counter,
          );
        }
      } else if ((await _cache.readCandles(symbol, dailyInterval, from: fromDay)).isEmpty) {
        rethrow; // nothing to fall back on
      }
    }
    await _applyDaily(symbol);
    final out = await cached();
    if (out.candles.isEmpty) throw const NotFoundFailure('No price data');
    return out;
  });

  Future<List<Candle>> cachedDaily(String symbol, DateTime from) => _cache.readCandles(symbol, dailyInterval, from: from);

  // ---- search, profile, fees -----------------------------------------------

  Future<Result<SearchResponse>> search(String query) => _guard(() async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const SearchResponse(results: [], news: []);
    final markets = (await this.markets()).valueOrNull ?? await _cachedMarkets();
    bool matches(LunoMarket m) =>
        m.pair.toLowerCase().contains(q) ||
        m.base.toLowerCase() == q ||
        m.counter.toLowerCase() == q ||
        lunoAssetName(m.base).toLowerCase().contains(q) ||
        (yahooAssetCode(m.base).toLowerCase() == q);
    return SearchResponse(
      results: [
        for (final m in markets.where(matches).take(12))
          SearchResult(
            symbol: lunoSymbol(m.pair),
            name: '${lunoAssetName(m.base)} / ${m.counter}',
            quoteType: 'CRYPTOCURRENCY',
            exchange: 'Luno',
          ),
      ],
      news: const [],
    );
  });

  Future<Result<AssetProfile>> profile(String symbol) async {
    final pair = lunoPairOf(symbol);
    final base = pair.substring(0, pair.length - 3);
    return Result.ok(AssetProfile(description: '${lunoAssetName(base)} traded against ${pair.substring(pair.length - 3)} on Luno.'));
  }

  final Map<String, ({LunoFeeInfo fee, DateTime at})> _fees = {};

  /// Fee schedule for the user's account on this pair (needs an API key), cached for a day.
  Future<Result<LunoFeeInfo>> feeInfo(String symbol) => _guard(() async {
    final pair = lunoPairOf(symbol);
    final hit = _fees[pair];
    if (hit != null && _clock.now().difference(hit.at) < feeTtl) return hit.fee;
    final fee = await _client.feeInfo(pair);
    _fees[pair] = (fee: fee, at: _clock.now());
    return fee;
  });

  Future<void> clearCache() async {
    await _db.delete(_db.lunoMarketsCache).go();
    _fees.clear();
  }
}

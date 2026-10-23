import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/market.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../db/app_database.dart';
import '../yahoo/yahoo_client.dart';
import 'price_cache.dart';
import '../yahoo/yahoo_mappers.dart';

final _log = Logger('MarketDataRepository');

/// Yahoo Finance backed [MarketDataRepository] with drift caches.
class MarketDataRepositoryImpl implements MarketDataRepository {
  MarketDataRepositoryImpl(this._db, this._client, [this._clock = const SystemClock()]);

  final AppDatabase _db;
  final YahooClient _client;
  final Clock _clock;

  static const dailyInterval = '1d';

  /// Quotes younger than this are served from cache; equal to the refresh debounce so a repeat refresh costs nothing.
  static const quoteTtl = Duration(seconds: 30);
  static const intradayTtl = Duration(minutes: 2);
  static const dailyTtl = Duration(hours: 6);
  static const profileTtl = Duration(hours: 24);

  int _epoch(DateTime d) => PriceCache.epoch(d);

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

  // ---- quotes --------------------------------------------------------------

  Map<String, Quote> _quotes(List<QuoteCacheRow> rows) {
    final out = <String, Quote>{};
    for (final r in rows) {
      try {
        out[r.symbol] = Quote.fromJson((jsonDecode(r.payloadJson) as Map).cast<String, Object?>());
      } on Object catch (e) {
        _log.warning('Dropping unreadable cached quote ${r.symbol}: $e');
      }
    }
    return out;
  }

  @override
  Stream<Map<String, Quote>> watchQuotes() => _db.select(_db.quoteCache).watch().map(_quotes);

  @override
  Future<Map<String, Quote>> quotesSnapshot() async => _quotes(await _db.select(_db.quoteCache).get());

  @override
  Future<Result<QuoteRefresh>> refreshQuotes(Iterable<String> symbols, {bool force = false}) async {
    final requested = symbols.toSet().toList();
    if (requested.isEmpty) return const Result.ok(QuoteRefresh(fetched: 0, requested: 0));

    final cached = {for (final r in await _db.select(_db.quoteCache).get()) r.symbol: r};
    final started = _clock.now();
    final unique = [
      for (final s in requested)
        if (force || cached[s] == null || started.difference(cached[s]!.fetchedAt) >= quoteTtl) s,
    ];
    final failures = <AppFailure>[];
    var fetched = requested.length - unique.length; // fresh enough: already available

    for (var i = 0; i < unique.length; i += YahooClient.quoteBatchSize) {
      final chunk = unique.sublist(i, (i + YahooClient.quoteBatchSize).clamp(0, unique.length));
      try {
        final body = await _client.quote(chunk);
        final now = _clock.now();
        final quotes = YahooMappers.quotes(body, now);
        await _db.batch((b) {
          for (final q in quotes) {
            var merged = q;
            // Keep enrichment (sector, beta, ...) that the quote endpoint does not return.
            final prev = cached[q.symbol];
            if (prev != null) {
              try {
                final p = Quote.fromJson((jsonDecode(prev.payloadJson) as Map).cast<String, Object?>());
                merged = q.copyWith(sector: p.sector, industry: p.industry, beta: p.beta);
              } on Object {
                // ignore unreadable previous payload
              }
            }
            b.insert(
              _db.quoteCache,
              QuoteCacheCompanion.insert(symbol: q.symbol, payloadJson: jsonEncode(merged.toJson()), fetchedAt: now),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        fetched += quotes.length;
      } on AppFailure catch (f) {
        failures.add(f);
        if (f is RateLimitedFailure || f is ConfigFailure) break; // no point continuing
      }
    }
    if (fetched == 0 && failures.isNotEmpty) return Result.err(failures.first);
    return Result.ok(QuoteRefresh(fetched: fetched, requested: requested.length, failures: failures));
  }

  // ---- history -------------------------------------------------------------

  late final PriceCache _cache = PriceCache(_db, _clock);

  Future<void> _storeCandles(String symbol, String interval, List<Candle> candles) => _cache.storeCandles(symbol, interval, candles);

  Future<void> _storeEvents(PriceHistory h) async {
    await _db.batch((b) {
      b.insertAll(_db.dividendEventsCache, [
        for (final d in h.dividends) DividendEventsCacheCompanion.insert(symbol: h.symbol, exDate: d.exDate, amount: d.amount),
      ], mode: InsertMode.insertOrReplace);
      b.insertAll(_db.splitEventsCache, [
        for (final s in h.splits)
          SplitEventsCacheCompanion.insert(symbol: h.symbol, date: s.date, numerator: s.numerator, denominator: s.denominator),
      ], mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<Candle>> _readCandles(String symbol, String interval, {DateTime? from}) => _cache.readCandles(symbol, interval, from: from);

  Future<HistoryMetaRow?> _meta(String symbol, String interval) => _cache.meta(symbol, interval);

  Future<void> _writeMeta(String symbol, String interval, int oldest, int newest, String? currency) =>
      _cache.writeMeta(symbol, interval, oldest, newest, currency);

  Future<PriceHistory> _withEvents(String symbol, List<Candle> candles, String? currency, {DateTime? from}) async {
    final divs = await (_db.select(_db.dividendEventsCache)..where((t) => t.symbol.equals(symbol))).get();
    final splits = await (_db.select(_db.splitEventsCache)..where((t) => t.symbol.equals(symbol))).get();
    bool keep(DateTime d) => from == null || !d.isBefore(from);
    return PriceHistory(
      symbol: symbol,
      candles: candles,
      currency: currency,
      dividends: [
        for (final d in divs)
          if (keep(d.exDate)) DividendEvent(symbol: symbol, exDate: d.exDate, amount: d.amount),
      ]..sort((a, b) => a.exDate.compareTo(b.exDate)),
      splits: [
        for (final s in splits)
          if (keep(s.date)) SplitEvent(symbol: symbol, date: s.date, numerator: s.numerator, denominator: s.denominator),
      ]..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  @override
  Future<Result<PriceHistory>> chartHistory(String symbol, ChartRange range, {bool force = false}) => _guard(() async {
    final interval = range.interval;
    final now = _clock.now().toUtc();
    final start = range.start(now);
    final meta = await _meta(symbol, interval);
    final ttl = range.intraday ? intradayTtl : dailyTtl;

    final fresh = meta != null && now.difference(meta.fetchedAt.toUtc()) < ttl;
    // The meta window records what was *requested* (not just the first candle), so
    // recently listed symbols whose data starts later still count as covered.
    final covers = meta != null && (start == null || _epoch(start) >= meta.oldestTs - 86400);
    if (!force && fresh && covers) {
      final candles = await _readCandles(symbol, interval, from: start);
      if (candles.isNotEmpty) return _withEvents(symbol, candles, meta.currency, from: start);
    }

    try {
      final body = await _client.chart(symbol, range: range.yahooRange, interval: interval);
      final h = YahooMappers.chart(body, intraday: range.intraday, fallbackSymbol: symbol);
      if (h.candles.isEmpty) throw const NotFoundFailure('No price data for this range');
      if (range.intraday) {
        // Intraday windows are replaced wholesale to avoid stale partial sessions.
        await (_db.delete(_db.priceHistoryCache)..where((t) => t.symbol.equals(symbol) & t.interval.equals(interval))).go();
      }
      await _storeCandles(symbol, interval, h.candles);
      await _storeEvents(h);
      final first = _epoch(h.candles.first.time);
      final covered = start == null ? first : (_epoch(start) < first ? _epoch(start) : first);
      final prevOldest = meta?.oldestTs;
      await _writeMeta(
        symbol,
        interval,
        range.intraday || prevOldest == null ? covered : (covered < prevOldest ? covered : prevOldest),
        _epoch(h.candles.last.time),
        h.currency,
      );
      return PriceHistory(symbol: symbol, candles: h.candles, dividends: h.dividends, splits: h.splits, currency: h.currency);
    } on AppFailure {
      // Fall back to whatever is cached so offline users still see a chart.
      final cached = await _readCandles(symbol, interval, from: start);
      if (cached.isNotEmpty) return _withEvents(symbol, cached, meta?.currency, from: start);
      rethrow;
    }
  });

  @override
  Future<Result<PriceHistory>> dailyHistory(String symbol, DateTime from, {bool force = false}) => _guard(() async {
    final now = _clock.now().toUtc();
    final fromDay = DateTime.utc(from.year, from.month, from.day);
    final meta = await _meta(symbol, dailyInterval);
    final hasHistory = meta != null && meta.oldestTs <= _epoch(fromDay.add(const Duration(days: 5)));
    final fresh = meta != null && now.difference(meta.fetchedAt.toUtc()) < dailyTtl;

    if (hasHistory && fresh && !force) {
      return _withEvents(symbol, await _readCandles(symbol, dailyInterval, from: fromDay), meta.currency, from: fromDay);
    }

    // Incremental: refetch a week of overlap when history already covers [from], else the whole window.
    final period1 = hasHistory ? meta.newestTs - 7 * 86400 : _epoch(fromDay.subtract(const Duration(days: 7)));
    final period2 = _epoch(now.add(const Duration(days: 1)));
    try {
      final body = await _client.chart(symbol, interval: dailyInterval, period1: period1, period2: period2);
      final h = YahooMappers.chart(body, intraday: false, fallbackSymbol: symbol);
      if (h.candles.isNotEmpty) await _storeCandles(symbol, dailyInterval, h.candles);
      await _storeEvents(h);
      final oldest = h.candles.isEmpty
          ? (meta?.oldestTs ?? period1)
          : (period1 < _epoch(h.candles.first.time) ? period1 : _epoch(h.candles.first.time));
      final newest = h.candles.isEmpty ? (meta?.newestTs ?? period1) : _epoch(h.candles.last.time);
      await _writeMeta(
        symbol,
        dailyInterval,
        hasHistory ? meta.oldestTs : oldest,
        hasHistory ? (newest > meta.newestTs ? newest : meta.newestTs) : newest,
        h.currency ?? meta?.currency,
      );
    } on AppFailure {
      final cached = await _readCandles(symbol, dailyInterval, from: fromDay);
      if (cached.isEmpty) rethrow; // nothing to fall back on
    }
    return _withEvents(symbol, await _readCandles(symbol, dailyInterval, from: fromDay), meta?.currency, from: fromDay);
  });

  @override
  Future<List<Candle>> cachedDaily(String symbol, DateTime from) => _readCandles(symbol, dailyInterval, from: from);

  // ---- search & profile ----------------------------------------------------

  @override
  Future<Result<SearchResponse>> search(String query) => _guard(() async {
    final q = query.trim();
    if (q.isEmpty) return const SearchResponse(results: [], news: []);
    return YahooMappers.search(await _client.search(q));
  });

  @override
  Future<Result<AssetProfile>> profile(String symbol, {bool force = false}) => _guard(() async {
    final row = await (_db.select(_db.profileCache)..where((t) => t.symbol.equals(symbol))).getSingleOrNull();
    final now = _clock.now();
    if (!force && row != null && now.difference(row.fetchedAt) < profileTtl) {
      return YahooMappers.profile((jsonDecode(row.payloadJson) as Map).cast<String, Object?>());
    }
    try {
      final body = await _client.quoteSummary(symbol);
      final profile = YahooMappers.profile(body);
      await _db
          .into(_db.profileCache)
          .insertOnConflictUpdate(ProfileCacheCompanion.insert(symbol: symbol, payloadJson: jsonEncode(body), fetchedAt: now));
      await _enrichQuote(symbol, profile);
      return profile;
    } on AppFailure {
      if (row != null) return YahooMappers.profile((jsonDecode(row.payloadJson) as Map).cast<String, Object?>());
      rethrow;
    }
  });

  Future<void> _enrichQuote(String symbol, AssetProfile p) async {
    final row = await (_db.select(_db.quoteCache)..where((t) => t.symbol.equals(symbol))).getSingleOrNull();
    if (row == null) return;
    final q = Quote.fromJson((jsonDecode(row.payloadJson) as Map).cast<String, Object?>());
    final merged = q.copyWith(
      sector: p.sector,
      industry: p.industry,
      beta: p.beta,
      trailingPE: q.trailingPE ?? p.trailingPE,
      eps: q.eps ?? p.eps,
      dividendYield: q.dividendYield ?? p.dividendYield,
    );
    await (_db.update(
      _db.quoteCache,
    )..where((t) => t.symbol.equals(symbol))).write(QuoteCacheCompanion(payloadJson: Value(jsonEncode(merged.toJson()))));
  }

  // ---- events --------------------------------------------------------------

  @override
  Stream<Map<String, List<DividendEvent>>> watchDividendEvents() => _db.select(_db.dividendEventsCache).watch().map((rows) {
    final out = <String, List<DividendEvent>>{};
    for (final r in rows) {
      out.putIfAbsent(r.symbol, () => []).add(DividendEvent(symbol: r.symbol, exDate: r.exDate, amount: r.amount, payDate: r.payDate));
    }
    return out;
  });

  @override
  Stream<Map<String, List<SplitEvent>>> watchSplitEvents() => _db.select(_db.splitEventsCache).watch().map((rows) {
    final out = <String, List<SplitEvent>>{};
    for (final r in rows) {
      out
          .putIfAbsent(r.symbol, () => [])
          .add(SplitEvent(symbol: r.symbol, date: r.date, numerator: r.numerator, denominator: r.denominator));
    }
    return out;
  });

  @override
  Future<void> clearCache() => _db.transaction(() async {
    await _db.delete(_db.quoteCache).go();
    await _db.delete(_db.profileCache).go();
    await _db.delete(_db.priceHistoryCache).go();
    await _db.delete(_db.historyMeta).go();
    await _db.delete(_db.dividendEventsCache).go();
    await _db.delete(_db.splitEventsCache).go();
  });
}

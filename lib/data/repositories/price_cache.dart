import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/market.dart';
import '../db/app_database.dart';

/// Reads and writes candle series in `price_history_cache` / `history_meta`, shared by every market data provider.
/// A series is identified by (symbol, interval); `history_meta` records which window was requested and when.
class PriceCache {
  PriceCache(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  static int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;
  static DateTime fromEpoch(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);

  Future<void> storeCandles(String symbol, String interval, List<Candle> candles) async {
    await _db.batch((b) {
      b.insertAll(_db.priceHistoryCache, [
        for (final c in candles)
          PriceHistoryCacheCompanion.insert(
            symbol: symbol,
            interval: interval,
            ts: epoch(c.time),
            open: c.open,
            high: c.high,
            low: c.low,
            close: c.close,
            adjClose: Value(c.adjClose),
            volume: Value(c.volume),
          ),
      ], mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<Candle>> readCandles(String symbol, String interval, {DateTime? from}) async {
    final q = _db.select(_db.priceHistoryCache)
      ..where((t) => t.symbol.equals(symbol) & t.interval.equals(interval))
      ..orderBy([(t) => OrderingTerm.asc(t.ts)]);
    if (from != null) q.where((t) => t.ts.isBiggerOrEqualValue(epoch(from)));
    return [
      for (final r in await q.get())
        Candle(time: fromEpoch(r.ts), open: r.open, high: r.high, low: r.low, close: r.close, adjClose: r.adjClose, volume: r.volume),
    ];
  }

  Future<HistoryMetaRow?> meta(String symbol, String interval) =>
      (_db.select(_db.historyMeta)..where((t) => t.symbol.equals(symbol) & t.interval.equals(interval))).getSingleOrNull();

  Future<void> writeMeta(String symbol, String interval, int oldest, int newest, String? currency) => _db
      .into(_db.historyMeta)
      .insertOnConflictUpdate(
        HistoryMetaCompanion.insert(
          symbol: symbol,
          interval: interval,
          oldestTs: oldest,
          newestTs: newest,
          currency: Value(currency),
          fetchedAt: _clock.now(),
        ),
      );

  Future<void> deleteSeries(String symbol, String interval) =>
      (_db.delete(_db.priceHistoryCache)..where((t) => t.symbol.equals(symbol) & t.interval.equals(interval))).go();
}

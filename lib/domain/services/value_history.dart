import 'package:decimal/decimal.dart';

import '../entities/enums.dart';
import '../entities/portfolio.dart';
import 'fx.dart';

/// Ascending daily closes with forward-fill lookup.
class PriceSeries {
  PriceSeries(this.dates, this.closes) : assert(dates.length == closes.length);

  final List<DateTime> dates;
  final List<double> closes;

  bool get isEmpty => dates.isEmpty;

  /// Close on or before [date]; null before the first observation.
  double? at(DateTime date) {
    if (dates.isEmpty) return null;
    var lo = 0, hi = dates.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (!dates[mid].isAfter(date)) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found < 0 ? null : closes[found];
  }
}

class ValuePoint {
  const ValuePoint(this.date, this.value);
  final DateTime date;
  final double value;
}

class ValueHistoryResult {
  const ValueHistoryResult(this.points, {this.incomplete = false});
  final List<ValuePoint> points;

  /// True when some holdings lacked price history for part of the range.
  final bool incomplete;

  static const empty = ValueHistoryResult([]);
}

/// Reconstructs daily portfolio value from transactions, price history and FX.
///
/// Chart output uses `double`: it is display-only derived data, whereas stored
/// money values and totals use `Decimal`.
class ValueHistory {
  const ValueHistory();

  ValueHistoryResult compute({
    required List<PortfolioTransaction> transactions,
    required Map<String, PriceSeries> prices,
    required Map<String, String> symbolCurrency,
    required Map<String, FxSeries> fxToBase,
    required String base,
    required HistoryRange range,
    required DateTime now,
    int maxPoints = 600,
  }) {
    final txs = transactions.where((t) => t.symbol != null && _moves(t.type)).toList()
      ..sort((a, b) {
        final c = a.tradeDate.compareTo(b.tradeDate);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    if (txs.isEmpty) return ValueHistoryResult.empty;

    final today = DateTime.utc(now.year, now.month, now.day);
    final first = txs.first.tradeDate;
    var start = range.start(now) ?? first;
    if (start.isBefore(first)) start = first;
    if (start.isAfter(today)) return ValueHistoryResult.empty;

    // Yahoo closes are split-adjusted, so the running quantity is also restated
    // in post-split terms for dates before a split via the cumulative future split factor.
    final splitsBySymbol = <String, List<PortfolioTransaction>>{};
    for (final t in txs.where((t) => t.type == TxType.split)) {
      splitsBySymbol.putIfAbsent(t.symbol!, () => []).add(t);
    }

    final qty = <String, double>{};
    var i = 0;
    var incomplete = false;
    final totalDays = today.difference(start).inDays + 1;
    final step = (totalDays / maxPoints).ceil().clamp(1, 1 << 20);
    final points = <ValuePoint>[];

    // Replay transactions up to the day before [start].
    DateTime day = start;
    void applyUpTo(DateTime d) {
      while (i < txs.length && !txs[i].tradeDate.isAfter(d)) {
        final t = txs[i++];
        final s = t.symbol!;
        final q = t.quantity.toDouble();
        switch (t.type) {
          case TxType.buy || TxType.openingPosition:
            qty[s] = (qty[s] ?? 0) + q;
          case TxType.sell:
            qty[s] = ((qty[s] ?? 0) - q).clamp(0, double.infinity);
          case TxType.split:
            if (t.price != Decimal.zero) qty[s] = (qty[s] ?? 0) * (q / t.price.toDouble());
          default:
            break;
        }
      }
    }

    for (var n = 0; n < totalDays; n += step) {
      day = start.add(Duration(days: n));
      applyUpTo(day);
      var total = 0.0;
      for (final e in qty.entries) {
        if (e.value <= 0) continue;
        final series = prices[e.key];
        final px = series?.at(day);
        if (px == null) {
          incomplete = true;
          continue;
        }
        var factor = 1.0;
        for (final s in splitsBySymbol[e.key] ?? const <PortfolioTransaction>[]) {
          if (s.tradeDate.isAfter(day) && s.price != Decimal.zero) {
            factor *= s.quantity.toDouble() / s.price.toDouble();
          }
        }
        final ccy = symbolCurrency[e.key] ?? base;
        final rate = ccy == base ? Decimal.one : (fxToBase[ccy]?.at(day) ?? Decimal.one);
        total += e.value * factor * px * rate.toDouble();
      }
      points.add(ValuePoint(day, total));
    }
    if (points.isNotEmpty && points.last.date != today) {
      applyUpTo(today);
      // Recompute final point for today so the series ends on the latest day.
      var total = 0.0;
      for (final e in qty.entries) {
        if (e.value <= 0) continue;
        final px = prices[e.key]?.at(today);
        if (px == null) continue;
        var factor = 1.0;
        for (final s in splitsBySymbol[e.key] ?? const <PortfolioTransaction>[]) {
          if (s.tradeDate.isAfter(today) && s.price != Decimal.zero) {
            factor *= s.quantity.toDouble() / s.price.toDouble();
          }
        }
        final ccy = symbolCurrency[e.key] ?? base;
        final rate = ccy == base ? Decimal.one : (fxToBase[ccy]?.at(today) ?? Decimal.one);
        total += e.value * factor * px * rate.toDouble();
      }
      points.add(ValuePoint(today, total));
    }
    return ValueHistoryResult(points, incomplete: incomplete);
  }

  bool _moves(TxType t) => t == TxType.buy || t == TxType.sell || t == TxType.openingPosition || t == TxType.split;
}

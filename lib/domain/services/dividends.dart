import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../entities/enums.dart';
import '../entities/market.dart';
import '../entities/portfolio.dart';
import 'fx.dart';
import 'holdings_engine.dart';
import 'valuation.dart';

class MonthlyIncome {
  const MonthlyIncome(this.month, this.amountBase);
  final DateTime month; // first day of month (UTC)
  final Decimal amountBase;
}

class SymbolIncome {
  const SymbolIncome(this.symbol, this.amountBase);
  final String symbol;
  final Decimal amountBase;
}

/// A Yahoo dividend event that the user held shares for but has not recorded.
class DetectedDividend {
  const DetectedDividend({
    required this.portfolioId,
    required this.symbol,
    required this.exDate,
    required this.perShare,
    required this.quantity,
    required this.currency,
  });
  final int portfolioId;
  final String symbol;
  final DateTime exDate;
  final Decimal perShare;
  final Decimal quantity;
  final String currency;

  Decimal get amount => perShare * quantity;
}

class DetectedSplit {
  const DetectedSplit({required this.portfolioId, required this.event});
  final int portfolioId;
  final SplitEvent event;
}

class DividendService {
  const DividendService({this.engine = const HoldingsEngine()});

  final HoldingsEngine engine;

  Decimal _amountBase(PortfolioTransaction t) {
    final amount = t.quantity == Decimal.zero ? t.price : t.gross;
    return (amount - t.fees) * t.fxRateToBase;
  }

  /// Dividends received per month for the trailing [months] months ending at [now].
  List<MonthlyIncome> monthly(Iterable<PortfolioTransaction> txs, DateTime now, {int months = 12}) {
    final buckets = <DateTime, Decimal>{};
    for (var i = months - 1; i >= 0; i--) {
      buckets[DateTime.utc(now.year, now.month - i, 1)] = Decimal.zero;
    }
    for (final t in txs.where((t) => t.type == TxType.dividend)) {
      final key = DateTime.utc(t.tradeDate.year, t.tradeDate.month, 1);
      if (buckets.containsKey(key)) buckets[key] = buckets[key]! + _amountBase(t);
    }
    return buckets.entries.map((e) => MonthlyIncome(e.key, e.value)).toList();
  }

  List<SymbolIncome> bySymbol(Iterable<PortfolioTransaction> txs, {DateTime? since}) {
    final sums = <String, Decimal>{};
    for (final t in txs.where((t) => t.type == TxType.dividend && t.symbol != null)) {
      if (since != null && t.tradeDate.isBefore(since)) continue;
      sums.update(t.symbol!, (v) => v + _amountBase(t), ifAbsent: () => _amountBase(t));
    }
    return sums.entries.map((e) => SymbolIncome(e.key, e.value)).toList()..sort((a, b) => b.amountBase.compareTo(a.amountBase));
  }

  Decimal totalReceived(Iterable<PortfolioTransaction> txs, {DateTime? since}) => txs
      .where((t) => t.type == TxType.dividend && (since == null || !t.tradeDate.isBefore(since)))
      .fold(Decimal.zero, (s, t) => s + _amountBase(t));

  /// Finds dividend events held on the ex-date that have no matching recorded transaction.
  List<DetectedDividend> detect({
    required Map<int, List<PortfolioTransaction>> byPortfolio,
    required Map<String, List<DividendEvent>> events,
    required Map<String, String> currencies,
    required DateTime now,
  }) {
    final out = <DetectedDividend>[];
    for (final entry in byPortfolio.entries) {
      final txs = entry.value;
      final symbols = txs.where((t) => t.symbol != null && t.type != TxType.dividend).map((t) => t.symbol!).toSet();
      for (final symbol in symbols) {
        final evs = [...(events[symbol] ?? const <DividendEvent>[])]..sort((a, b) => a.exDate.compareTo(b.exDate));
        final recorded = txs.where((t) => t.type == TxType.dividend && t.symbol == symbol).toList()
          ..sort((a, b) => a.tradeDate.compareTo(b.tradeDate));
        final used = <int>{};
        final firstTrade = txs
            .where((t) => t.symbol == symbol && t.type != TxType.dividend)
            .map((t) => t.tradeDate)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        for (final ev in evs) {
          if (ev.exDate.isAfter(now) || !ev.exDate.isAfter(firstTrade)) continue;
          // Ex-date is the first day without entitlement: holdings at close of the day before.
          final qty = engine.quantityAt(txs, symbol, ev.exDate.subtract(const Duration(days: 1)));
          if (qty <= Decimal.zero) continue;
          final match = recorded.indexWhere(
            (t) =>
                !used.contains(t.id) &&
                !t.tradeDate.isBefore(ev.exDate.subtract(const Duration(days: 2))) &&
                !t.tradeDate.isAfter(ev.exDate.add(const Duration(days: 60))),
          );
          if (match >= 0) {
            used.add(recorded[match].id);
            continue;
          }
          out.add(
            DetectedDividend(
              portfolioId: entry.key,
              symbol: symbol,
              exDate: ev.exDate,
              perShare: dec(ev.amount),
              quantity: qty,
              currency: currencies[symbol] ?? 'USD',
            ),
          );
        }
      }
    }
    out.sort((a, b) => b.exDate.compareTo(a.exDate));
    return out;
  }

  /// Splits reported by Yahoo for held symbols that were not recorded as `split` transactions.
  List<DetectedSplit> detectSplits({
    required Map<int, List<PortfolioTransaction>> byPortfolio,
    required Map<String, List<SplitEvent>> events,
  }) {
    final out = <DetectedSplit>[];
    for (final entry in byPortfolio.entries) {
      final txs = entry.value;
      final symbols = txs.where((t) => t.symbol != null && t.type != TxType.dividend).map((t) => t.symbol!).toSet();
      for (final symbol in symbols) {
        final firstTrade = txs.where((t) => t.symbol == symbol).map((t) => t.tradeDate).reduce((a, b) => a.isBefore(b) ? a : b);
        final recorded = txs.where((t) => t.type == TxType.split && t.symbol == symbol);
        for (final ev in events[symbol] ?? const <SplitEvent>[]) {
          if (!ev.date.isAfter(firstTrade)) continue;
          if (engine.quantityAt(txs, symbol, ev.date.subtract(const Duration(days: 1))) <= Decimal.zero) continue;
          final already = recorded.any((t) => t.tradeDate.difference(ev.date).inDays.abs() <= 3);
          if (!already) out.add(DetectedSplit(portfolioId: entry.key, event: ev));
        }
      }
    }
    return out;
  }

  /// Projected annual income in base currency: trailing-12-month dividend per share × current quantity.
  Decimal projectedAnnual({
    required Iterable<HoldingValuation> holdings,
    required Map<String, List<DividendEvent>> events,
    required FxRates fx,
    required String base,
    required DateTime now,
  }) {
    final cutoff = DateTime.utc(now.year - 1, now.month, now.day);
    var total = Decimal.zero;
    for (final h in holdings) {
      final ttm = (events[h.symbol] ?? const <DividendEvent>[])
          .where((e) => e.exDate.isAfter(cutoff) && !e.exDate.isAfter(now))
          .fold(0.0, (s, e) => s + e.amount);
      final rate = fx.rate(h.currency, base) ?? Decimal.one;
      total += dec(ttm) * h.quantity * rate;
    }
    return total;
  }
}

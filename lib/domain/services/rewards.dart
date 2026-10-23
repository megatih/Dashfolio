import 'package:decimal/decimal.dart';

import '../entities/enums.dart';
import '../entities/portfolio.dart';
import 'dividends.dart';

/// Income received in kind (Luno interest/earn): each `reward` is valued at its market price when it was received.
class RewardService {
  const RewardService();

  Decimal _valueBase(PortfolioTransaction t) => t.gross * t.fxRateToBase;

  Iterable<PortfolioTransaction> _rewards(Iterable<PortfolioTransaction> txs) => txs.where((t) => t.type == TxType.reward);

  /// Rewards received per month for the trailing [months] months ending at [now], in the base currency.
  List<MonthlyIncome> monthly(Iterable<PortfolioTransaction> txs, DateTime now, {int months = 12}) {
    final buckets = <DateTime, Decimal>{for (var i = months - 1; i >= 0; i--) DateTime.utc(now.year, now.month - i, 1): Decimal.zero};
    for (final t in _rewards(txs)) {
      final key = DateTime.utc(t.tradeDate.year, t.tradeDate.month, 1);
      if (buckets.containsKey(key)) buckets[key] = buckets[key]! + _valueBase(t);
    }
    return [for (final e in buckets.entries) MonthlyIncome(e.key, e.value)];
  }

  /// Value received per asset symbol, largest first.
  List<SymbolIncome> byAsset(Iterable<PortfolioTransaction> txs, {DateTime? since}) {
    final sums = <String, Decimal>{};
    for (final t in _rewards(txs).where((t) => t.symbol != null)) {
      if (since != null && t.tradeDate.isBefore(since)) continue;
      sums.update(t.symbol!, (v) => v + _valueBase(t), ifAbsent: () => _valueBase(t));
    }
    return [for (final e in sums.entries) SymbolIncome(e.key, e.value)]..sort((a, b) => b.amountBase.compareTo(a.amountBase));
  }

  Decimal totalReceived(Iterable<PortfolioTransaction> txs, {DateTime? since}) =>
      _rewards(txs).where((t) => since == null || !t.tradeDate.isBefore(since)).fold(Decimal.zero, (s, t) => s + _valueBase(t));
}

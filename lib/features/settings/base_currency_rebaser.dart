import 'package:decimal/decimal.dart';

import '../../core/decimal_ext.dart';
import '../../core/result.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/services/fx.dart';

class RebaseResult {
  const RebaseResult({required this.updated, required this.fromHistory, required this.fromChain, required this.unresolved});

  final int updated;

  /// Rates taken from Yahoo's historical FX series.
  final int fromHistory;

  /// Rates derived as (old rate × current old→new rate) because no history was available.
  final int fromChain;

  /// Transactions left unchanged because no rate could be found at all.
  final int unresolved;
}

/// Recomputes `fxRateToBase` on every transaction after the base currency changes.
class BaseCurrencyRebaser {
  BaseCurrencyRebaser({required this.portfolios, required this.market});

  final PortfolioRepository portfolios;
  final MarketDataRepository market;

  Future<RebaseResult> rebase({required String oldBase, required String newBase, required FxRates currentFx}) async {
    if (oldBase == newBase) return const RebaseResult(updated: 0, fromHistory: 0, fromChain: 0, unresolved: 0);
    final txs = await portfolios.getTransactions();
    if (txs.isEmpty) return const RebaseResult(updated: 0, fromHistory: 0, fromChain: 0, unresolved: 0);

    final earliest = txs.map((t) => t.tradeDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final currencies = {for (final t in txs) t.currency}..remove(newBase);

    final series = <String, FxSeries>{};
    for (final c in currencies) {
      final r = await market.dailyHistory(fxSymbol(c, newBase), earliest.subtract(const Duration(days: 10)));
      if (r case Ok(:final value) when value.candles.isNotEmpty) {
        series[c] = FxSeries([for (final x in value.candles) x.time], [for (final x in value.candles) dec(x.close)]);
      }
    }
    final oldToNew = currentFx.rate(oldBase, newBase);

    var updated = 0, hist = 0, chain = 0, unresolved = 0;
    for (final t in txs) {
      Decimal? rate;
      if (t.currency == newBase) {
        rate = Decimal.one;
      } else {
        rate = series[t.currency]?.at(t.tradeDate);
        if (rate != null) {
          hist++;
        } else if (oldToNew != null) {
          rate = t.fxRateToBase * oldToNew;
          chain++;
        }
      }
      if (rate == null) {
        unresolved++;
        continue;
      }
      await portfolios.updateTransaction(t.copyWith(fxRateToBase: rate));
      updated++;
    }
    return RebaseResult(updated: updated, fromHistory: hist, fromChain: chain, unresolved: unresolved);
  }
}

/// Summary line for UI/toasts.
String describeRebase(RebaseResult r) {
  final parts = <String>['Updated ${r.updated} exchange rates'];
  if (r.fromChain > 0) parts.add('${r.fromChain} estimated from today\'s rate');
  if (r.unresolved > 0) parts.add('${r.unresolved} could not be converted — refresh and review them');
  return parts.join(' · ');
}

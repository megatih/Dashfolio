import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../domain/entities/enums.dart';
import '../domain/entities/market.dart';
import '../domain/entities/portfolio.dart';
import '../domain/services/fx.dart';
import '../domain/services/holdings_engine.dart';
import '../domain/services/valuation.dart';
import '../domain/services/value_history.dart';
import 'providers.dart';

const _engine = HoldingsEngine();
const _valuation = Valuation();

/// Non-archived portfolios.
final activePortfoliosProvider = Provider<List<Portfolio>>((ref) {
  final all = ref.watch(portfoliosProvider).value ?? const <Portfolio>[];
  return all.where((p) => !p.archived).toList();
});

final transactionsByPortfolioProvider = Provider<Map<int, List<PortfolioTransaction>>>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? const <PortfolioTransaction>[];
  final out = <int, List<PortfolioTransaction>>{};
  for (final t in txs) {
    out.putIfAbsent(t.portfolioId, () => []).add(t);
  }
  return out;
});

/// FX rates derived from cached Yahoo FX quotes (`EURUSD=X`, ...).
final fxRatesProvider = Provider<FxRates>((ref) {
  final quotes = ref.watch(quotesProvider).value ?? const <String, Quote>{};
  final prices = <String, double>{
    for (final q in quotes.values)
      if (q.symbol.endsWith('=X') && q.price != null) q.symbol: q.price!,
  };
  return QuoteFxRates(prices);
});

/// Ids of the portfolios a selection refers to (`null` = every active portfolio).
List<Portfolio> portfoliosFor(List<Portfolio> active, int? id) => id == null ? active : active.where((p) => p.id == id).toList();

/// Replayed positions for one portfolio.
final positionsProvider = Provider.family<PortfolioPositions?, int>((ref, portfolioId) {
  final portfolios = ref.watch(portfoliosProvider).value;
  final txs = ref.watch(transactionsByPortfolioProvider)[portfolioId];
  if (portfolios == null) return null;
  final p = portfolios.where((p) => p.id == portfolioId).firstOrNull;
  if (p == null) return null;
  return _engine.replay(txs ?? const [], p.costMethod);
});

/// Valued holdings and totals for a portfolio, or for all active portfolios when [portfolioId] is null.
final valuedPortfolioProvider = Provider.family<ValuedPortfolio?, int?>((ref, portfolioId) {
  final portfoliosAsync = ref.watch(portfoliosProvider);
  if (!portfoliosAsync.hasValue || !ref.watch(transactionsProvider).hasValue) return null;
  final active = ref.watch(activePortfoliosProvider);
  final selected = portfoliosFor(active, portfolioId);
  final quotes = ref.watch(quotesProvider).value ?? const <String, Quote>{};
  final fx = ref.watch(fxRatesProvider);
  final base = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
  final byPortfolio = ref.watch(transactionsByPortfolioProvider);
  final instruments = ref.watch(instrumentsProvider).value ?? const {};
  final names = {for (final i in instruments.values) i.symbol: i.name};

  final parts = <ValuedPortfolio>[];
  for (final p in selected) {
    final positions = _engine.replay(byPortfolio[p.id] ?? const [], p.costMethod);
    parts.add(_valuation.value(positions, quotes, fx, base, names: names));
  }
  if (parts.length == 1) return parts.single;
  final totals = parts.fold(PortfolioTotals.empty, (s, v) => s + v.totals);
  final holdings = _valuation.merge(parts.map((p) => p.holdings));
  return ValuedPortfolio(holdings, totals, [for (final p in parts) ...p.closed]);
});

/// Symbols that need prices for a selection of portfolios (open or past holdings).
Set<String> symbolsFor(Iterable<PortfolioTransaction> txs) => {
  for (final t in txs)
    if (t.symbol != null) t.symbol!,
};

// ---- value history -------------------------------------------------------------

@immutable
class HistoryKey {
  const HistoryKey(this.portfolioId, this.range);
  final int? portfolioId;
  final HistoryRange range;

  @override
  bool operator ==(Object other) => other is HistoryKey && other.portfolioId == portfolioId && other.range == range;

  @override
  int get hashCode => Object.hash(portfolioId, range);
}

/// Inputs for one value-history computation (sendable to an isolate).
class HistoryArgs {
  const HistoryArgs(this.txs, this.prices, this.currencies, this.fx, this.base, this.range, this.now);
  final List<PortfolioTransaction> txs;
  final Map<String, PriceSeries> prices;
  final Map<String, String> currencies;
  final Map<String, FxSeries> fx;
  final String base;
  final HistoryRange range;
  final DateTime now;
}

/// Pure computation; also usable synchronously from tests.
ValueHistoryResult runHistory(HistoryArgs a) => const ValueHistory().compute(
  transactions: a.txs,
  prices: a.prices,
  symbolCurrency: a.currencies,
  fxToBase: a.fx,
  base: a.base,
  range: a.range,
  now: a.now,
);

/// Executes the value-history computation; off the UI thread by default, injectable for tests.
final historyRunnerProvider = Provider<Future<ValueHistoryResult> Function(HistoryArgs)>(
  (ref) =>
      (args) => compute(runHistory, args),
);

/// Runs [fn] over [items] with at most [limit] concurrent calls.
Future<List<R>> mapPool<T, R>(Iterable<T> items, int limit, Future<R> Function(T) fn) async {
  final list = items.toList();
  final results = List<R?>.filled(list.length, null);
  var next = 0;
  Future<void> worker() async {
    while (true) {
      final i = next++;
      if (i >= list.length) return;
      results[i] = await fn(list[i]);
    }
  }

  await Future.wait([for (var i = 0; i < limit.clamp(1, list.isEmpty ? 1 : list.length); i++) worker()]);
  return results.cast<R>();
}

PriceSeries _series(List<Candle> candles) => PriceSeries([for (final c in candles) c.time], [for (final c in candles) c.close]);

/// Daily portfolio value for the dashboard chart.
final valueHistoryProvider = FutureProvider.family<ValueHistoryResult, HistoryKey>((ref, key) async {
  final active = ref.watch(activePortfoliosProvider);
  final byPortfolio = ref.watch(transactionsByPortfolioProvider);
  final selected = portfoliosFor(active, key.portfolioId);
  final txs = [for (final p in selected) ...?byPortfolio[p.id]];
  final moves = txs
      .where((t) => t.symbol != null && const {TxType.buy, TxType.sell, TxType.openingPosition, TxType.split}.contains(t.type))
      .toList();
  if (moves.isEmpty) return ValueHistoryResult.empty;

  final repo = ref.watch(marketDataRepositoryProvider);
  final base = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
  final clock = ref.watch(clockProvider);
  final quotes = ref.read(quotesProvider).value ?? const <String, Quote>{};
  final now = clock.now();

  final first = moves.map((t) => t.tradeDate).reduce((a, b) => a.isBefore(b) ? a : b);
  var from = key.range.start(now) ?? first;
  if (from.isBefore(first)) from = first;

  final symbols = symbolsFor(moves);
  final currencies = <String, String>{for (final s in symbols) s: quotes[s]?.currency ?? moves.firstWhere((t) => t.symbol == s).currency};
  final fxCurrencies = {
    for (final c in currencies.values)
      if (c != base) c,
  };

  final prices = <String, PriceSeries>{};
  await mapPool(symbols, 4, (String s) async {
    final r = await repo.dailyHistory(s, from);
    if (r case Ok(:final value) when value.candles.isNotEmpty) prices[s] = _series(value.candles);
  });

  final fxSeries = <String, FxSeries>{};
  final fxNow = ref.read(fxRatesProvider);
  await mapPool(fxCurrencies, 4, (String c) async {
    final r = await repo.dailyHistory(fxSymbol(c, base), from);
    if (r case Ok(:final value) when value.candles.isNotEmpty) {
      fxSeries[c] = FxSeries([for (final x in value.candles) x.time], [for (final x in value.candles) Decimal.parse(x.close.toString())]);
    } else {
      final rate = fxNow.rate(c, base);
      if (rate != null) fxSeries[c] = FxSeries.constant(rate);
    }
  });

  final args = HistoryArgs(moves, prices, currencies, fxSeries, base, key.range, now);
  return ref.read(historyRunnerProvider)(args);
});

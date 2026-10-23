import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../core/decimal_ext.dart';
import '../../core/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/market.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/services/dividends.dart';
import '../../domain/services/rewards.dart';

const _svc = DividendService();
const _rewards = RewardService();

class IncomeSummary {
  const IncomeSummary({
    required this.monthly,
    required this.bySymbol,
    required this.received12m,
    required this.receivedAll,
    required this.projectedAnnual,
    required this.yieldOnCost,
    required this.detected,
    required this.detectedSplits,
    required this.rewardsMonthly,
    required this.rewardsByAsset,
    required this.rewards12m,
    required this.rewardsAll,
  });

  final List<MonthlyIncome> monthly;
  final List<SymbolIncome> bySymbol;
  final Decimal received12m;
  final Decimal receivedAll;
  final Decimal projectedAnnual;
  final Decimal? yieldOnCost;
  final List<DetectedDividend> detected;
  final List<DetectedSplit> detectedSplits;

  /// Luno interest/earn rewards, valued when received. Counted as income but excluded from [projectedAnnual].
  final List<MonthlyIncome> rewardsMonthly;
  final List<SymbolIncome> rewardsByAsset;
  final Decimal rewards12m;
  final Decimal rewardsAll;
}

/// Income analytics across all active portfolios.
final incomeSummaryProvider = Provider<IncomeSummary?>((ref) {
  if (!ref.watch(transactionsProvider).hasValue || !ref.watch(portfoliosProvider).hasValue) return null;
  final active = ref.watch(activePortfoliosProvider);
  final byPortfolio = ref.watch(transactionsByPortfolioProvider);
  final events = ref.watch(dividendEventsProvider).value ?? const <String, List<DividendEvent>>{};
  final splits = ref.watch(splitEventsProvider).value ?? const <String, List<SplitEvent>>{};
  final quotes = ref.watch(quotesProvider).value ?? const <String, Quote>{};
  final fx = ref.watch(fxRatesProvider);
  final base = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
  final now = ref.watch(clockProvider).now();
  final valued = ref.watch(valuedPortfolioProvider(null));

  final scoped = {for (final p in active) p.id: byPortfolio[p.id] ?? const <PortfolioTransaction>[]};
  final all = [for (final l in scoped.values) ...l];
  final cutoff = DateTime.utc(now.year - 1, now.month, now.day);

  final received12 = _svc.totalReceived(all, since: cutoff);
  final projected = valued == null
      ? Decimal.zero
      : _svc.projectedAnnual(holdings: valued.holdings, events: events, fx: fx, base: base, now: now);
  final cost = valued?.totals.costBasis ?? Decimal.zero;

  final currencies = {for (final e in quotes.entries) e.key: e.value.currency};
  for (final t in all) {
    if (t.symbol != null) currencies.putIfAbsent(t.symbol!, () => t.currency);
  }

  return IncomeSummary(
    monthly: _svc.monthly(all, now),
    bySymbol: _svc.bySymbol(all, since: cutoff),
    received12m: received12,
    receivedAll: _svc.totalReceived(all),
    projectedAnnual: projected,
    yieldOnCost: cost == Decimal.zero ? null : projected.div(cost),
    detected: _svc.detect(byPortfolio: scoped, events: events, currencies: currencies, now: now),
    detectedSplits: _svc.detectSplits(byPortfolio: scoped, events: splits),
    rewardsMonthly: _rewards.monthly(all, now),
    rewardsByAsset: _rewards.byAsset(all, since: cutoff),
    rewards12m: _rewards.totalReceived(all, since: cutoff),
    rewardsAll: _rewards.totalReceived(all),
  );
});

class UpcomingDividend {
  const UpcomingDividend({required this.symbol, required this.exDate, this.payDate});
  final String symbol;
  final DateTime exDate;
  final DateTime? payDate;
}

/// Ex-dividend dates (from cached/fetched profiles) for currently held symbols.
final upcomingDividendsProvider = FutureProvider.autoDispose<List<UpcomingDividend>>((ref) async {
  final valued = ref.watch(valuedPortfolioProvider(null));
  if (valued == null) return const [];
  final repo = ref.read(marketDataRepositoryProvider);
  final today = ref.read(clockProvider).now();
  final symbols = [
    for (final h in valued.holdings)
      if (h.quote?.quoteType == 'EQUITY' || h.quote?.quoteType == 'ETF') h.symbol,
  ].take(40);
  final out = <UpcomingDividend>[];
  await mapPool(symbols, 3, (String s) async {
    final r = await repo.profile(s);
    if (r case Ok(:final value)) {
      final ex = value.events.exDividendDate;
      if (ex != null && !ex.isBefore(DateTime.utc(today.year, today.month, today.day))) {
        out.add(UpcomingDividend(symbol: s, exDate: ex, payDate: value.events.dividendPayDate));
      }
    }
  });
  out.sort((a, b) => a.exDate.compareTo(b.exDate));
  return out;
});

/// Records a detected dividend as a `dividend` transaction in its portfolio.
Future<void> recordDetectedDividend(WidgetRef ref, DetectedDividend d) async {
  final base = ref.read(appSettingsProvider).baseCurrency;
  final rate = ref.read(fxRatesProvider).rate(d.currency, base) ?? Decimal.one;
  await ref
      .read(portfolioRepositoryProvider)
      .addTransaction(
        PortfolioTransaction(
          id: 0,
          portfolioId: d.portfolioId,
          symbol: d.symbol,
          type: TxType.dividend,
          tradeDate: d.exDate,
          quantity: d.quantity,
          price: d.perShare,
          fees: Decimal.zero,
          currency: d.currency,
          fxRateToBase: rate,
          notes: 'Recorded from Yahoo dividend data',
          createdAt: ref.read(clockProvider).now(),
        ),
      );
}

Future<void> recordDetectedSplit(WidgetRef ref, DetectedSplit d) async {
  final quotes = ref.read(quotesProvider).value;
  await ref
      .read(portfolioRepositoryProvider)
      .addTransaction(
        PortfolioTransaction(
          id: 0,
          portfolioId: d.portfolioId,
          symbol: d.event.symbol,
          type: TxType.split,
          tradeDate: d.event.date,
          quantity: dec(d.event.numerator),
          price: dec(d.event.denominator),
          fees: Decimal.zero,
          currency: quotes?[d.event.symbol]?.currency ?? 'USD',
          fxRateToBase: Decimal.one,
          notes: 'Recorded from Yahoo split data',
          createdAt: ref.read(clockProvider).now(),
        ),
      );
}

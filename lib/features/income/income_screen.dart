import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/decimal_ext.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/services/dividends.dart';
import '../../routing/routes.dart';
import '../charts/chart_utils.dart';
import '../common/page_scaffold.dart';
import '../common/small_widgets.dart';
import 'income_providers.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(incomeSummaryProvider);
    final currency = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));

    Widget body;
    if (summary == null) {
      body = const Column(
        children: [
          AppCardSkeleton(height: 140),
          SizedBox(height: AppSpace.s5),
          AppCardSkeleton(height: 280),
        ],
      );
    } else if (summary.receivedAll == Decimal.zero &&
        summary.rewardsAll == Decimal.zero &&
        summary.detected.isEmpty &&
        summary.projectedAnnual == Decimal.zero) {
      body = const Padding(
        padding: EdgeInsets.only(top: AppSpace.s8),
        child: AppEmptyState(
          icon: AppIcon.savings,
          title: 'No income yet',
          message: 'Record dividend transactions, refresh prices so Dashfolio can find dividends paid on your holdings, or connect Luno to see interest rewards.',
        ),
      );
    } else {
      body = LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          const gap = AppSpace.s5;
          final chart = _MonthlyCard(title: 'Dividends by month', months: summary.monthly, currency: currency);
          final symbols = _BySymbolCard(
            title: 'By symbol (12 months)',
            items: summary.bySymbol,
            emptyText: 'No dividends received in the last 12 months',
            currency: currency,
          );
          final hasRewards = summary.rewardsAll != Decimal.zero;
          final rewardCards = [
            _MonthlyCard(title: 'Rewards by month', months: summary.rewardsMonthly, currency: currency),
            _BySymbolCard(
              title: 'Rewards by asset (12 months)',
              items: summary.rewardsByAsset,
              emptyText: 'No rewards received in the last 12 months',
              currency: currency,
            ),
          ];
          final side = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (summary.detected.isNotEmpty) ...[_DetectedCard(summary: summary, currency: currency), const SizedBox(height: gap)],
              if (summary.detectedSplits.isNotEmpty) ...[_SplitsCard(summary: summary), const SizedBox(height: gap)],
              const _UpcomingCard(),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Summary(summary: summary, currency: currency),
              const SizedBox(height: gap),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          chart,
                          const SizedBox(height: gap),
                          symbols,
                          if (hasRewards)
                            for (final c in rewardCards) ...[const SizedBox(height: gap), c],
                        ],
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(flex: 5, child: side),
                  ],
                )
              else ...[
                side,
                const SizedBox(height: gap),
                chart,
                const SizedBox(height: gap),
                symbols,
                if (hasRewards)
                  for (final c in rewardCards) ...[const SizedBox(height: gap), c],
              ],
            ],
          );
        },
      );
    }
    return PageScaffold(title: 'Income', child: body);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary, required this.currency});

  final IncomeSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return AppCard(
      child: Wrap(
        spacing: AppSpace.s10,
        runSpacing: AppSpace.s5,
        children: [
          _Big(label: 'Received (12 months)', value: Fmt.currency(s.received12m, currency)),
          _Big(
            label: 'Projected annual income',
            value: Fmt.currency(s.projectedAnnual, currency),
            sub: 'trailing dividends × current shares',
          ),
          _Big(label: 'Yield on cost', value: s.yieldOnCost == null ? '—' : Fmt.percent(s.yieldOnCost, signed: false)),
          _Big(label: 'Received (all time)', value: Fmt.currency(s.receivedAll, currency)),
          if (s.rewardsAll != Decimal.zero) ...[
            _Big(label: 'Rewards (12 months)', value: Fmt.currency(s.rewards12m, currency), sub: 'interest in crypto, at receipt value'),
            _Big(label: 'Rewards (all time)', value: Fmt.currency(s.rewardsAll, currency)),
          ],
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.value, this.sub});
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: context.text.labelMedium!.copyWith(color: context.app.textMuted)),
      const SizedBox(height: 4),
      Text(value, style: context.text.headlineMedium),
      if (sub != null) Text(sub!, style: context.text.bodySmall),
    ],
  );
}

class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.title, required this.months, required this.currency});

  final String title;
  final List<MonthlyIncome> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final maxV = months.map((m) => m.amountBase.toDouble()).fold(0.0, (a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title),
          const SizedBox(height: AppSpace.s4),
          Semantics(
            label: '$title: ${months.map((m) => '${DateFormat.MMM().format(m.month)} ${Fmt.currency(m.amountBase, currency)}').join(', ')}',
            child: SizedBox(
              height: 220,
              child: ExcludeSemantics(
                child: BarChart(
                  BarChartData(
                    maxY: maxV == 0 ? 1 : maxV * 1.2,
                    minY: 0,
                    gridData: buildGrid(context),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          getTitlesWidget: (v, meta) => v == meta.min
                              ? const SizedBox.shrink()
                              : SideTitleWidget(
                                  meta: meta,
                                  child: Text(compactAxisValue(v), style: context.text.labelSmall!.copyWith(fontSize: 10)),
                                ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= months.length) return const SizedBox.shrink();
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(DateFormat.MMM().format(months[i].month), style: context.text.labelSmall!.copyWith(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => n.text,
                        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                          '${DateFormat.yMMM().format(months[group.x].month)}\n',
                          context.text.labelSmall!.copyWith(color: n.surface.withValues(alpha: 0.8)),
                          children: [
                            TextSpan(
                              text: Fmt.currency(months[group.x].amountBase, currency),
                              style: context.text.titleSmall!.copyWith(color: n.surface),
                            ),
                          ],
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < months.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: months[i].amountBase.toDouble(),
                              width: 16,
                              color: n.accent,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BySymbolCard extends StatelessWidget {
  const _BySymbolCard({required this.title, required this.items, required this.emptyText, required this.currency});

  final String title;
  final List<SymbolIncome> items;
  final String emptyText;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final maxV = items.isEmpty ? Decimal.one : items.first.amountBase;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title),
          const SizedBox(height: AppSpace.s3),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
              child: Text(emptyText, style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
            ),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
              child: Row(
                children: [
                  SymbolBadge(i.symbol, size: 34),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.symbol, style: context.text.titleSmall),
                        const SizedBox(height: 4),
                        AppProgress(value: maxV == Decimal.zero ? 0 : i.amountBase.div(maxV).toDouble().clamp(0, 1), height: 6),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.s4),
                  AppMoneyText(i.amountBase, currency: currency, style: context.text.titleSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetectedCard extends ConsumerWidget {
  const _DetectedCard({required this.summary, required this.currency});

  final IncomeSummary summary;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = summary.detected;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Unrecorded dividends (${items.length})',
            trailing: items.length > 1 ? AppTextButton(label: 'Record all', onPressed: () => _recordAll(context, ref, items)) : null,
          ),
          const SizedBox(height: AppSpace.s1),
          Text(
            'Yahoo reports these were paid on shares you held. Record them to include them in your income.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpace.s3),
          for (final d in items.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d.symbol} · ${Fmt.date(d.exDate)}', style: context.text.titleSmall),
                        Text(
                          '${Fmt.number(d.quantity, maxDecimals: 4)} × ${Fmt.currency(d.perShare, d.currency)} = ${Fmt.currency(d.amount, d.currency)}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppButton(label: 'Record', compact: true, onPressed: () => _record(context, ref, d)),
                ],
              ),
            ),
          if (items.length > 12) Text('+ ${items.length - 12} more', style: context.text.bodySmall),
        ],
      ),
    );
  }

  Future<void> _record(BuildContext context, WidgetRef ref, DetectedDividend d) async {
    await recordDetectedDividend(ref, d);
    if (context.mounted) showAppToast(context, 'Recorded ${d.symbol} dividend');
  }

  Future<void> _recordAll(BuildContext context, WidgetRef ref, List<DetectedDividend> items) async {
    for (final d in items) {
      await recordDetectedDividend(ref, d);
    }
    if (context.mounted) showAppToast(context, 'Recorded ${items.length} dividends');
  }
}

class _SplitsCard extends ConsumerWidget {
  const _SplitsCard({required this.summary});
  final IncomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Stock splits to record'),
          const SizedBox(height: AppSpace.s1),
          Text('A split changes your share count. Record it so quantities and cost per share stay correct.', style: context.text.bodySmall),
          const SizedBox(height: AppSpace.s3),
          for (final s in summary.detectedSplits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.event.symbol} · ${s.event.numerator}-for-${s.event.denominator} on ${Fmt.date(s.event.date)}',
                      style: context.text.titleSmall,
                    ),
                  ),
                  AppButton(label: 'Record', compact: true, onPressed: () => recordDetectedSplit(ref, s)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends ConsumerWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.app;
    final async = ref.watch(upcomingDividendsProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Upcoming'),
          const SizedBox(height: AppSpace.s2),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.s3),
              child: AppSkeleton(height: 40),
            ),
            error: (_, _) => Text('Upcoming dividends are unavailable.', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
                    child: Text(
                      'No upcoming ex-dividend dates for your holdings.',
                      style: context.text.bodyMedium!.copyWith(color: n.textMuted),
                    ),
                  )
                : Column(
                    children: [
                      for (final u in items.take(10))
                        AppRow(
                          leading: SymbolBadge(u.symbol, size: 34),
                          title: u.symbol,
                          titleStyle: context.text.titleSmall,
                          subtitle: 'Ex-dividend ${Fmt.date(u.exDate)}${u.payDate == null ? '' : ' · pays ${Fmt.date(u.payDate!)}'}',
                          subtitleStyle: context.text.bodySmall,
                          onTap: () => context.push(Routes.quote(u.symbol)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

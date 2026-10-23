import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/services/allocation.dart';
import '../../domain/services/valuation.dart';
import '../charts/allocation_donut.dart';
import '../charts/value_history_chart.dart';
import '../common/page_scaffold.dart';

/// Portfolio value over time with a range selector.
class ValueHistoryCard extends ConsumerStatefulWidget {
  const ValueHistoryCard({super.key, required this.portfolioId, required this.currency});

  final int? portfolioId;
  final String currency;

  @override
  ConsumerState<ValueHistoryCard> createState() => _ValueHistoryCardState();
}

class _ValueHistoryCardState extends ConsumerState<ValueHistoryCard> {
  HistoryRange _range = HistoryRange.m3;

  @override
  Widget build(BuildContext context) {
    final key = HistoryKey(widget.portfolioId, _range);
    final history = ref.watch(valueHistoryProvider(key));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final selector = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AppSegmented<HistoryRange>(
                  dense: true,
                  selected: _range,
                  onChanged: (r) => setState(() => _range = r),
                  segments: [for (final r in HistoryRange.values) AppSegment(r, r.label)],
                ),
              );
              if (c.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Portfolio value'),
                    const SizedBox(height: AppSpace.s3),
                    selector,
                  ],
                );
              }
              return Row(
                children: [
                  const Expanded(child: SectionTitle('Portfolio value')),
                  selector,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.s4),
          history.when(
            data: (r) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueHistoryChart(points: r.points, currency: widget.currency),
                if (r.incomplete)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s2),
                    child: Text(
                      'Some holdings lack price history for part of this range, so the line may understate value.',
                      style: context.text.bodySmall,
                    ),
                  ),
              ],
            ),
            loading: () => const SizedBox(height: 260, child: Center(child: AppSkeleton(height: 220, radius: 12))),
            error: (e, _) => SizedBox(
              height: 260,
              child: AppErrorRetry(error: e, compact: true, onRetry: () => ref.invalidate(valueHistoryProvider(key))),
            ),
          ),
        ],
      ),
    );
  }
}

/// Allocation donut with a group-by toggle.
class AllocationCard extends StatefulWidget {
  const AllocationCard({super.key, required this.holdings, required this.currency});

  final List<HoldingValuation> holdings;
  final String currency;

  @override
  State<AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends State<AllocationCard> {
  AllocationGroup _group = AllocationGroup.assetClass;

  @override
  Widget build(BuildContext context) {
    final slices = const Allocation().group(widget.holdings, _group);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Allocation'),
          const SizedBox(height: AppSpace.s3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AppSegmented<AllocationGroup>(
              dense: true,
              selected: _group,
              onChanged: (g) => setState(() => _group = g),
              segments: [for (final g in AllocationGroup.values) AppSegment(g, g.label)],
            ),
          ),
          const SizedBox(height: AppSpace.s5),
          AllocationDonut(slices: slices, currency: widget.currency),
        ],
      ),
    );
  }
}

/// Helper to read the base currency in cards.
String baseCurrencyOf(WidgetRef ref) => ref.watch(appSettingsProvider.select((s) => s.baseCurrency));

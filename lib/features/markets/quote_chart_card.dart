import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/result.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/market.dart';
import '../charts/price_chart.dart';
import '../common/page_scaffold.dart';

typedef ChartKey = ({String symbol, ChartRange range, int stamp});

/// Candles for a symbol/range; recomputed after a manual refresh.
final chartHistoryProvider = FutureProvider.autoDispose.family<PriceHistory, ChartKey>((ref, key) async {
  final repo = ref.watch(marketDataRepositoryProvider);
  final r = await repo.chartHistory(key.symbol, key.range);
  return switch (r) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Price chart with range selector, line/candle toggle and optional trade markers.
class QuoteChartCard extends ConsumerStatefulWidget {
  const QuoteChartCard({
    super.key,
    required this.symbol,
    required this.currency,
    this.markers = const [],
    this.ranges = const [
      ChartRange.d1,
      ChartRange.d5,
      ChartRange.m1,
      ChartRange.m6,
      ChartRange.ytd,
      ChartRange.y1,
      ChartRange.y5,
      ChartRange.max,
    ],
    this.initialRange = ChartRange.m6,
    this.title = 'Price',
  });

  final String symbol;
  final String currency;
  final List<TradeMarker> markers;
  final List<ChartRange> ranges;
  final ChartRange initialRange;
  final String title;

  @override
  ConsumerState<QuoteChartCard> createState() => _QuoteChartCardState();
}

class _QuoteChartCardState extends ConsumerState<QuoteChartCard> {
  late ChartRange _range = widget.ranges.contains(widget.initialRange) ? widget.initialRange : widget.ranges.first;
  bool _candles = false;

  @override
  Widget build(BuildContext context) {
    final stamp = ref.watch(appSettingsProvider.select((s) => s.lastRefreshAt?.millisecondsSinceEpoch ?? 0));
    final key = (symbol: widget.symbol, range: _range, stamp: stamp);
    final async = ref.watch(chartHistoryProvider(key));

    final controls = Wrap(
      spacing: AppSpace.s3,
      runSpacing: AppSpace.s3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: AppSegmented<ChartRange>(
            dense: true,
            selected: _range,
            onChanged: (r) => setState(() => _range = r),
            segments: [for (final r in widget.ranges) AppSegment(r, r.label)],
          ),
        ),
        AppSegmented<bool>(
          dense: true,
          selected: _candles,
          onChanged: (v) => setState(() => _candles = v),
          segments: const [
            AppSegment(false, 'Line', icon: AppIcon.showChart),
            AppSegment(true, 'Candles', icon: AppIcon.candlestickChart),
          ],
        ),
      ],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(widget.title),
          const SizedBox(height: AppSpace.s3),
          controls,
          const SizedBox(height: AppSpace.s4),
          async.when(
            data: (h) => PriceChart(
              candles: h.candles,
              currency: widget.currency,
              candlestick: _candles,
              intraday: _range.intraday,
              markers: _candles ? const [] : widget.markers,
            ),
            loading: () => const SizedBox(height: 300, child: Center(child: AppSkeleton(height: 260, radius: 12))),
            error: (e, _) => SizedBox(
              height: 300,
              child: AppErrorRetry(error: e, compact: true, onRetry: () => ref.invalidate(chartHistoryProvider(key))),
            ),
          ),
          if (async.value?.via case final via?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: Text(
                'Chart data via $via. Connect Luno to use Luno\'s own candles.',
                style: context.text.bodySmall!.copyWith(color: context.app.textMuted),
              ),
            ),
          if (_candles && !_range.intraday)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: Text('Pinch or scroll to zoom the candles.', style: context.text.bodySmall),
            ),
        ],
      ),
    );
  }
}

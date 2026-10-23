import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/app/app_ui.dart';
import '../../domain/entities/market.dart';
import 'chart_utils.dart';

/// A buy/sell marker plotted on a price line.
class TradeMarker {
  const TradeMarker({required this.date, required this.isBuy});
  final DateTime date;
  final bool isBuy;
}

/// Interactive price chart: line or candlesticks, optional volume sub-chart and trade markers.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.candles,
    required this.currency,
    this.candlestick = false,
    this.intraday = false,
    this.showVolume = true,
    this.markers = const [],
    this.height = 300,
  });

  final List<Candle> candles;
  final String currency;
  final bool candlestick;
  final bool intraday;
  final bool showVolume;
  final List<TradeMarker> markers;
  final double height;

  static const double _axisWidth = 52;

  String _fmt(double v) => NumberFormat.simpleCurrency(name: currency).format(v);

  String _stamp(Candle c) => intraday ? DateFormat.yMMMd().add_Hm().format(c.time.toLocal()) : DateFormat.yMMMd().format(c.time);

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    if (candles.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Not enough data for this range', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
        ),
      );
    }
    final span = candles.last.time.difference(candles.first.time);
    final up = candles.last.close >= candles.first.close;
    final color = up ? n.gain : n.loss;

    final lows = candles.map((c) => candlestick ? c.low : c.close).reduce((a, b) => a < b ? a : b);
    final highs = candles.map((c) => candlestick ? c.high : c.close).reduce((a, b) => a > b ? a : b);
    final pad = (highs - lows) * 0.08;
    final minY = lows - pad, maxY = highs + (pad == 0 ? highs * 0.02 + 0.01 : pad);

    final titles = buildTitles(
      context,
      length: candles.length,
      showLeft: false,
      showRight: true,
      reservedLeft: _axisWidth,
      bottomLabel: (i) => axisDateLabel(candles[i].time, span: span, intraday: intraday),
    );

    final animation = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200);

    final Widget main = candlestick
        ? CandlestickChart(
            CandlestickChartData(
              minX: -0.5,
              maxX: candles.length - 0.5,
              minY: minY,
              maxY: maxY,
              gridData: buildGrid(context),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              candlestickSpots: [
                for (var i = 0; i < candles.length; i++)
                  CandlestickSpot(
                    x: i.toDouble(),
                    open: candles[i].open,
                    high: candles[i].high,
                    low: candles[i].low,
                    close: candles[i].close,
                  ),
              ],
              candlestickPainter: DefaultCandlestickPainter(
                candlestickStyleProvider: (spot, index) {
                  final c = spot.close >= spot.open ? n.gain : n.loss;
                  return CandlestickStyle(
                    lineColor: c,
                    lineWidth: 1.2,
                    bodyStrokeColor: c,
                    bodyStrokeWidth: 1,
                    bodyFillColor: spot.close >= spot.open ? c.withValues(alpha: 0.85) : c,
                    bodyWidth: (300 / candles.length).clamp(2, 10).toDouble(),
                    bodyRadius: 1,
                  );
                },
              ),
              candlestickTouchData: CandlestickTouchData(
                touchTooltipData: CandlestickTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  maxContentWidth: 220,
                  getTooltipColor: (_) => n.tooltipBackground,
                  getTooltipItems: (painter, spot, index) {
                    final i = spot.x.round().clamp(0, candles.length - 1);
                    final c = candles[i];
                    final base = context.text.labelSmall!.copyWith(color: n.tooltipForeground);
                    return CandlestickTooltipItem(
                      '${_stamp(c)}\n',
                      textStyle: base.copyWith(color: n.tooltipForeground.withValues(alpha: 0.8)),
                      children: [
                        TextSpan(
                          text: 'O ${_fmt(c.open)}  H ${_fmt(c.high)}\nL ${_fmt(c.low)}  C ${_fmt(c.close)}',
                          style: base.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            duration: animation,
            transformationConfig: const FlTransformationConfig(scaleAxis: FlScaleAxis.horizontal, minScale: 1, maxScale: 8),
          )
        : LineChart(
            LineChartData(
              minX: 0,
              maxX: (candles.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: buildGrid(context),
              borderData: FlBorderData(show: false),
              titlesData: titles,
              lineBarsData: [
                LineChartBarData(
                  spots: [for (var i = 0; i < candles.length; i++) FlSpot(i.toDouble(), candles[i].close)],
                  color: color,
                  barWidth: 2.2,
                  isCurved: candles.length < 90,
                  curveSmoothness: 0.12,
                  preventCurveOverShooting: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withValues(alpha: 0.24), color.withValues(alpha: 0)],
                    ),
                  ),
                ),
                if (markers.isNotEmpty) _markerBar(n),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => n.tooltipBackground,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      if (s.barIndex == 0)
                        LineTooltipItem(
                          '${_stamp(candles[s.x.round().clamp(0, candles.length - 1)])}\n',
                          context.text.labelSmall!.copyWith(color: n.tooltipForeground.withValues(alpha: 0.8)),
                          children: [
                            TextSpan(
                              text: _fmt(s.y),
                              style: context.text.titleSmall!.copyWith(color: n.tooltipForeground),
                            ),
                          ],
                        )
                      else
                        null,
                  ],
                ),
                getTouchedSpotIndicator: (bar, indices) => [
                  for (final _ in indices)
                    TouchedSpotIndicatorData(
                      FlLine(color: n.textMuted, strokeWidth: 1, dashArray: [3, 3]),
                      FlDotData(
                        getDotPainter: (a, b, c, d) =>
                            FlDotCirclePainter(radius: 4.5, color: color, strokeColor: n.surface, strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            duration: animation,
          );

    final summary = chartSummary(
      name: candlestick ? 'Candlestick price' : 'Price',
      first: candles.first.close,
      last: candles.last.close,
      format: _fmt,
      points: candles.length,
    );

    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: RepaintBoundary(child: main),
            ),
            if (showVolume && candles.any((c) => c.volume > 0)) ...[
              const SizedBox(height: AppSpace.s2),
              Padding(
                padding: const EdgeInsets.only(right: _axisWidth),
                child: SizedBox(
                  height: 56,
                  child: RepaintBoundary(child: _VolumeBars(candles: candles)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartBarData _markerBar(AppTheme n) {
    final spots = <FlSpot>[];
    final buys = <double>{};
    for (final m in markers) {
      // Nearest candle on or after the trade date.
      var idx = candles.indexWhere((c) => !c.time.isBefore(DateTime.utc(m.date.year, m.date.month, m.date.day)));
      if (idx < 0) idx = candles.length - 1;
      if (m.date.isBefore(candles.first.time.subtract(const Duration(days: 1)))) continue;
      spots.add(FlSpot(idx.toDouble(), candles[idx].close));
      if (m.isBuy) buys.add(idx.toDouble());
    }
    return LineChartBarData(
      spots: spots,
      color: Colors.transparent,
      barWidth: 0,
      dotData: FlDotData(
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 5, color: buys.contains(spot.x) ? n.gain : n.loss, strokeColor: n.surface, strokeWidth: 2),
      ),
    );
  }
}

class _VolumeBars extends StatelessWidget {
  const _VolumeBars({required this.candles});

  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final maxV = candles.map((c) => c.volume).reduce((a, b) => a > b ? a : b);
    final width = (300 / candles.length).clamp(1.5, 8).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxV * 1.1,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(enabled: false),
        alignment: BarChartAlignment.spaceBetween,
        barGroups: [
          for (var i = 0; i < candles.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: candles[i].volume,
                  width: width,
                  color: (candles[i].close >= candles[i].open ? n.gain : n.loss).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.zero,
                ),
              ],
            ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

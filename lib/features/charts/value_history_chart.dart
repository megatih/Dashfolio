import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../design_system/app/app_ui.dart';
import '../../core/format.dart';
import '../../domain/services/value_history.dart';
import 'chart_utils.dart';

import 'package:decimal/decimal.dart';

/// Area chart of portfolio value over time with a crosshair tooltip.
class ValueHistoryChart extends StatelessWidget {
  const ValueHistoryChart({super.key, required this.points, required this.currency, this.height = 260});

  final List<ValuePoint> points;
  final String currency;
  final double height;

  String _money(double v) => Fmt.currency(Decimal.parse(v.toStringAsFixed(2)), currency);

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Not enough history yet', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
        ),
      );
    }
    final up = points.last.value >= points.first.value;
    final color = up ? n.gain : n.loss;
    final span = points.last.date.difference(points.first.date);
    final spots = [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value)];
    final ys = points.map((p) => p.value);
    var minY = ys.reduce((a, b) => a < b ? a : b), maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.12;
    minY = (minY - pad).clamp(0, double.infinity);
    maxY += pad == 0 ? maxY * 0.05 + 1 : pad;

    return Semantics(
      label: chartSummary(
        name: 'Portfolio value',
        first: points.first.value,
        last: points.last.value,
        format: _money,
        points: points.length,
      ),
      child: SizedBox(
        height: height,
        child: ExcludeSemantics(
          child: RepaintBoundary(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: buildGrid(context),
                borderData: FlBorderData(show: false),
                titlesData: buildTitles(
                  context,
                  length: points.length,
                  bottomLabel: (i) => axisDateLabel(points[i].date, span: span),
                  reservedLeft: 52,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 2.5,
                    isCurved: points.length < 120,
                    curveSmoothness: 0.15,
                    preventCurveOverShooting: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => n.tooltipBackground,
                    fitInsideHorizontally: true,
                    maxContentWidth: 200,
                    getTooltipItems: (spots) => [
                      for (final s in spots)
                        LineTooltipItem(
                          '${Fmt.date(points[s.x.round().clamp(0, points.length - 1)].date)}\n',
                          context.text.labelSmall!.copyWith(color: n.tooltipForeground.withValues(alpha: 0.8)),
                          children: [
                            TextSpan(
                              text: _money(s.y),
                              style: context.text.titleSmall!.copyWith(color: n.tooltipForeground),
                            ),
                          ],
                        ),
                    ],
                  ),
                  getTouchedSpotIndicator: (bar, indices) => [
                    for (final _ in indices)
                      TouchedSpotIndicatorData(
                        FlLine(color: n.textMuted, strokeWidth: 1, dashArray: [3, 3]),
                        FlDotData(
                          getDotPainter: (a, b, c, d) =>
                              FlDotCirclePainter(radius: 5, color: color, strokeColor: n.surface, strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny line used inside list rows.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.width = 90, this.height = 32, this.color});

  final List<double> values;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    if (values.length < 2) return SizedBox(width: width, height: height);
    final c = color ?? (values.last >= values.first ? n.gain : n.loss);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                color: c,
                barWidth: 1.8,
                isCurved: true,
                curveSmoothness: 0.2,
                preventCurveOverShooting: true,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}

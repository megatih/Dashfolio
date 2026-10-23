import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../design_system/app/app_ui.dart';

/// Picks up to [count] evenly spaced indices (always including first and last).
List<int> labelIndices(int length, int count) {
  if (length <= 0) return const [];
  if (length <= count) return List.generate(length, (i) => i);
  return {for (var i = 0; i < count; i++) ((length - 1) * i / (count - 1)).round()}.toList();
}

String axisDateLabel(DateTime d, {required Duration span, bool intraday = false}) {
  if (intraday) return span.inDays >= 2 ? DateFormat.MMMd().add_Hm().format(d.toLocal()) : DateFormat.Hm().format(d.toLocal());
  if (span.inDays <= 400) return DateFormat.MMMd().format(d);
  return DateFormat.yMMM().format(d);
}

String compactAxisValue(double v) {
  final a = v.abs();
  if (a >= 1e12) return '${(v / 1e12).toStringAsFixed(1)}T';
  if (a >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
  if (a >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
  if (a >= 1e4) return '${(v / 1e3).toStringAsFixed(0)}K';
  if (a >= 100) return v.toStringAsFixed(0);
  if (a >= 1) return v.toStringAsFixed(2);
  return v.toStringAsFixed(4);
}

/// Standard grid/border/title styling for line and candle charts.
FlTitlesData buildTitles(
  BuildContext context, {
  required int length,
  required String Function(int index) bottomLabel,
  bool showLeft = true,
  bool showRight = false,
  double reservedLeft = 46,
}) {
  final n = context.app;
  final style = context.text.labelSmall!.copyWith(color: n.textMuted, fontSize: 10);
  final wanted = labelIndices(length, 4).toSet();
  return FlTitlesData(
    topTitles: const AxisTitles(),
    leftTitles: const AxisTitles(),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: showLeft || showRight,
        reservedSize: reservedLeft,
        getTitlesWidget: (v, meta) {
          if (v == meta.min || v == meta.max) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(compactAxisValue(v), style: style),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: length > 1,
        reservedSize: 26,
        interval: 1,
        getTitlesWidget: (v, meta) {
          final i = v.round();
          if (v != i.toDouble() || !wanted.contains(i) || i < 0 || i >= length) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            space: 6,
            fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
            child: Text(bottomLabel(i), style: style),
          );
        },
      ),
    ),
  );
}

FlGridData buildGrid(BuildContext context) {
  final n = context.app;
  return FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) => FlLine(color: n.outline.withValues(alpha: 0.6), strokeWidth: 1, dashArray: [4, 4]),
  );
}

/// Accessible text summary of a chart for screen readers.
String chartSummary({
  required String name,
  required double first,
  required double last,
  required String Function(double) format,
  int? points,
}) {
  final change = first == 0 ? 0 : (last - first) / first * 100;
  return '$name chart${points == null ? '' : ' with $points points'}, from ${format(first)} to ${format(last)}, ${change >= 0 ? 'up' : 'down'} ${change.abs().toStringAsFixed(2)} percent';
}

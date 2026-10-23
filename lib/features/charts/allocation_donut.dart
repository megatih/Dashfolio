import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/services/allocation.dart';

/// Distinct, theme-aware slice colors.
List<Color> sliceColors(AppTheme n) => n.chartSeries;

Color colorForSlice(AppTheme n, AllocationSlice s, int index) => s.isOther ? n.textMuted : sliceColors(n)[index % sliceColors(n).length];

/// Donut chart with a legend; hovering/tapping a slice shows its value in the center.
class AllocationDonut extends StatefulWidget {
  const AllocationDonut({super.key, required this.slices, required this.currency, this.size = 190});

  final List<AllocationSlice> slices;
  final String currency;
  final double size;

  @override
  State<AllocationDonut> createState() => _AllocationDonutState();
}

class _AllocationDonutState extends State<AllocationDonut> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final slices = const Allocation().collapseSmall(widget.slices);
    if (slices.isEmpty) {
      return SizedBox(
        height: widget.size,
        child: Center(
          child: Text('No holdings to allocate', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
        ),
      );
    }
    final total = widget.slices.fold(Decimal.zero, (s, e) => s + e.value);
    final active = _touched != null && _touched! < slices.length ? slices[_touched!] : null;

    final donut = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: widget.size * 0.32,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  touchCallback: (event, resp) {
                    final i = resp?.touchedSection?.touchedSectionIndex;
                    final next = (event.isInterestedForInteractions && i != null && i >= 0) ? i : null;
                    if (next != _touched) setState(() => _touched = next);
                  },
                ),
                sections: [
                  for (var i = 0; i < slices.length; i++)
                    PieChartSectionData(
                      value: slices[i].value.toDouble(),
                      color: colorForSlice(n, slices[i], i),
                      radius: _touched == i ? widget.size * 0.22 : widget.size * 0.18,
                      showTitle: false,
                    ),
                ],
              ),
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(active?.label ?? 'Total', style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                active != null
                    ? Fmt.percent(active.weight, signed: false, decimals: 1)
                    : Fmt.currency(total, widget.currency, compact: true),
                style: context.text.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );

    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slices.length; i++)
          MouseRegion(
            onEnter: (_) => setState(() => _touched = i),
            onExit: (_) => setState(() => _touched = null),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: colorForSlice(n, slices[i], i), borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  Expanded(
                    child: Text(slices[i].label, style: context.text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  Text(Fmt.percent(slices[i].weight, signed: false, decimals: 1), style: context.text.labelMedium),
                ],
              ),
            ),
          ),
      ],
    );

    return Semantics(
      label: 'Allocation: ${slices.map((s) => '${s.label} ${Fmt.percent(s.weight, signed: false, decimals: 1)}').join(', ')}',
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= widget.size * 2 + 40;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                donut,
                const SizedBox(width: AppSpace.s6),
                Expanded(child: legend),
              ],
            );
          }
          return Column(
            children: [
              donut,
              const SizedBox(height: AppSpace.s4),
              legend,
            ],
          );
        },
      ),
    );
  }
}

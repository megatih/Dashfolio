import 'package:flutter/cupertino.dart';

import 'cu_menu.dart';
import 'cu_surface.dart';
import 'cupertino_theme.dart';

class CuSwitch extends StatelessWidget {
  const CuSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scale = CupertinoMetrics.current.switchScale;
    final control = CupertinoSwitch(value: value, onChanged: onChanged);
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: onChanged != null,
      child: scale == 1 ? control : Transform.scale(scale: scale, child: control),
    );
  }
}

class CuSegment<T extends Object> {
  const CuSegment(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control. When the segments cannot fit the available width it becomes a pull-down pop-up button showing the
/// current value, so every option stays reachable at any width or text size.
class CuSegmented<T extends Object> extends StatelessWidget {
  const CuSegmented({super.key, required this.segments, required this.selected, required this.onChanged, this.dense = false});

  final List<CuSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final style = (dense || m.pointer ? t.footnote : t.subheadline).copyWith(color: p.label, fontWeight: FontWeight.w500);
    final pad = EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: m.pointer ? 3 : (dense ? 5 : 7));
    final scaler = MediaQuery.textScalerOf(context);

    // The sliding control gives every segment the width of the widest one.
    double natural() {
      var w = 0.0;
      for (final s in segments) {
        final tp = TextPainter(
          text: TextSpan(text: s.label, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final one = tp.width + pad.horizontal + (s.icon != null ? m.iconSize + 5 : 0);
        if (one > w) w = one;
        tp.dispose();
      }
      return w * segments.length + 8;
    }

    return LayoutBuilder(
      builder: (context, c) {
        final need = natural();
        // Under an unbounded parent (a horizontal scroller) fall back to what the window can show beside the page margins.
        final screen = MediaQuery.sizeOf(context).width;
        final budget = c.maxWidth.isFinite ? c.maxWidth : screen - 72 - (m.pointer ? m.sidebarWidth : 0);
        // HIG: segmented controls suit two to five options; more become a pop-up menu on a phone.
        if (need > budget || (segments.length > 5 && screen < 600)) return _collapsed(context, style);
        return CupertinoSlidingSegmentedControl<T>(
          groupValue: selected,
          onValueChanged: (v) {
            if (v != null) onChanged(v);
          },
          children: {
            for (final s in segments)
              s.value: Semantics(
                button: true,
                selected: s.value == selected,
                label: s.label,
                excludeSemantics: true,
                child: Padding(
                  padding: pad,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (s.icon != null) ...[Icon(s.icon, size: m.iconSize, color: p.label), const SizedBox(width: 5)],
                      Text(s.label, maxLines: 1, style: style),
                    ],
                  ),
                ),
              ),
          },
        );
      },
    );
  }

  Widget _collapsed(BuildContext context, TextStyle style) {
    final p = CupertinoPalette.of(context);
    final m = CupertinoMetrics.current;
    final current = segments.firstWhere((s) => s.value == selected, orElse: () => segments.first);
    return CuPopupMenu<T>(
      items: [for (final s in segments) CuMenuItem<T>(s.value, s.label, checked: s.value == selected)],
      onSelected: onChanged,
      builder: (context, open) => Semantics(
        button: true,
        label: current.label,
        excludeSemantics: true,
        onTap: open,
        child: CuTappable(
          onTap: open,
          child: Container(
            constraints: BoxConstraints(minHeight: m.pointer ? m.largeControlHeight : m.minHit),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: p.secondaryFill, borderRadius: BorderRadius.circular(m.groupRadius)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(current.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
                ),
                const SizedBox(width: 6),
                Icon(CupertinoIcons.chevron_up_chevron_down, size: m.iconSize - 4, color: p.secondaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CuChip extends StatelessWidget {
  const CuChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final fg = selected ? p.accent : p.label;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: selected ? p.accent.withValues(alpha: 0.15) : p.fill, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: m.iconSize - 4, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: t.caption1.copyWith(fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
    if (onTap == null) return Semantics(label: label, child: chip);
    return CuPressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      minSize: Size(0, m.pointer ? 24 : 36),
      builder: (context, s) => chip,
    );
  }
}

/// Linear progress. Indeterminate (null) shows a small activity indicator.
class CuProgress extends StatelessWidget {
  const CuProgress({super.key, this.value, this.height});

  final double? value;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final h = height ?? CupertinoMetrics.current.progressHeight;
    final v = value;
    if (v == null) return const Align(alignment: Alignment.centerLeft, child: CupertinoActivityIndicator(radius: 7));
    return Semantics(
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: SizedBox(
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: p.secondaryFill),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v.clamp(0, 1),
                child: ColoredBox(color: p.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CuSpinner extends StatelessWidget {
  const CuSpinner({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CupertinoActivityIndicator(radius: (size ?? 20) / 2, color: color);
}

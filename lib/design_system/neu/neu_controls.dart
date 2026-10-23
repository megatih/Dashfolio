import 'package:flutter/material.dart';

import 'neu_surface.dart';
import 'tokens.dart';

/// A neumorphic on/off switch: inset track with a raised thumb.
class NeuSwitch extends StatelessWidget {
  const NeuSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return NeuPressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      semanticLabel: semanticLabel,
      radius: 20,
      minSize: const Size(NeuTheme.minHit + 16, NeuTheme.minHit),
      builder: (context, _) => Center(
        child: NeuSurface(
          shape: NeuShape.concave,
          depth: 2,
          radius: 16,
          width: 56,
          height: 32,
          child: AnimatedAlign(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: NeuSurface(
                circle: true,
                depth: 1,
                color: value ? n.accent : null,
                width: 26,
                height: 26,
                child: value ? Icon(Icons.check, size: 14, color: n.onAccent) : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeuSegment<T> {
  const NeuSegment(this.value, this.label, {this.icon});
  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control: inset track, raised selected pill.
class NeuSegmentedControl<T> extends StatelessWidget {
  const NeuSegmentedControl({super.key, required this.segments, required this.selected, required this.onChanged, this.dense = false});

  final List<NeuSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final h = dense ? 36.0 : NeuTheme.minHit;
    return NeuSurface(
      shape: NeuShape.concave,
      depth: 2,
      radius: NeuTheme.radiusM,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in segments)
            NeuPressable(
              onTap: () => onChanged(s.value),
              semanticLabel: s.label,
              selected: s.value == selected,
              radius: NeuTheme.radiusS,
              minSize: Size(dense ? 40 : 48, h - 6),
              builder: (context, st) {
                final sel = s.value == selected;
                final style = context.text.labelMedium!.copyWith(color: sel ? n.accent : n.textMuted);
                return NeuSurface(
                  shape: sel ? NeuShape.convex : NeuShape.flat,
                  border: sel ? null : Border.all(color: Colors.transparent),
                  depth: 1,
                  radius: NeuTheme.radiusS,
                  padding: EdgeInsets.symmetric(horizontal: dense ? NeuTheme.s3 : NeuTheme.s4),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s.icon != null) ...[Icon(s.icon, size: 16, color: style.color), const SizedBox(width: 6)],
                      Text(s.label, style: style),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Small toggleable chip.
class NeuChip extends StatelessWidget {
  const NeuChip({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return NeuPressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      radius: 16,
      minSize: const Size(0, 36),
      builder: (context, s) => NeuSurface(
        shape: selected || s.pressed ? NeuShape.pressed : NeuShape.convex,
        depth: 1,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s3, vertical: NeuTheme.s1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: selected ? n.accent : n.textMuted), const SizedBox(width: 4)],
            Text(label, style: context.text.labelMedium!.copyWith(color: selected ? n.accent : n.text)),
          ],
        ),
      ),
    );
  }
}

/// Inset progress bar with an accent fill; indeterminate when [value] is null.
class NeuProgress extends StatelessWidget {
  const NeuProgress({super.key, this.value, this.height = 10});

  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return Semantics(
      value: value == null ? null : '${(value! * 100).round()}%',
      child: NeuSurface(
        shape: NeuShape.concave,
        depth: 1,
        radius: height / 2,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation(n.accent),
          ),
        ),
      ),
    );
  }
}

/// Themed slider with an inset track.
class NeuSlider extends StatelessWidget {
  const NeuSlider({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 1, this.divisions, this.label});

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: n.accent,
        inactiveTrackColor: n.surfaceAlt,
        thumbColor: n.surface,
        overlayColor: n.accent.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
      ),
      child: Slider(value: value, onChanged: onChanged, min: min, max: max, divisions: divisions, label: label),
    );
  }
}

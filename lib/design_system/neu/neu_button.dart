import 'package:flutter/material.dart';

import 'neu_surface.dart';
import 'tokens.dart';

enum NeuButtonKind { normal, primary, danger }

class NeuButton extends StatelessWidget {
  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = NeuButtonKind.normal,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NeuButtonKind kind;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final enabled = onPressed != null && !loading;
    final (Color? fill, Color fg) = switch (kind) {
      NeuButtonKind.primary => (n.accent, n.onAccent),
      NeuButtonKind.danger => (n.loss, n.isDark ? const Color(0xFF2A0A0A) : Colors.white),
      NeuButtonKind.normal => (null, n.text),
    };
    final style = context.text.labelLarge!.copyWith(color: enabled ? fg : n.textMuted);

    return NeuPressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      minSize: Size(compact ? 0 : NeuTheme.minHit, compact ? 36 : NeuTheme.minHit),
      builder: (context, s) {
        final pressed = s.pressed && enabled;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: enabled ? 1 : 0.55,
          child: NeuSurface(
            shape: pressed ? NeuShape.pressed : NeuShape.convex,
            depth: pressed ? 2 : 2,
            color: fill,
            padding: EdgeInsets.symmetric(horizontal: compact ? NeuTheme.s3 : NeuTheme.s5, vertical: NeuTheme.s2),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                else if (icon != null)
                  Icon(icon, size: 18, color: enabled ? fg : n.textMuted),
                if (loading || icon != null) const SizedBox(width: NeuTheme.s2),
                Flexible(
                  child: Text(label, style: style, overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.size = NeuTheme.minHit,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final enabled = onPressed != null && !loading;
    return NeuPressable(
      onTap: enabled ? onPressed : null,
      tooltip: tooltip,
      semanticLabel: tooltip,
      selected: selected,
      radius: NeuTheme.radiusM,
      minSize: Size(size, size),
      builder: (context, s) {
        final pressed = (s.pressed && enabled) || selected;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: onPressed == null ? 0.5 : 1,
          child: NeuSurface(
            shape: pressed ? NeuShape.pressed : NeuShape.convex,
            depth: 2,
            width: size,
            height: size,
            alignment: Alignment.center,
            child: loading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: n.accent))
                : Icon(icon, size: 20, color: selected ? n.accent : n.text),
          ),
        );
      },
    );
  }
}

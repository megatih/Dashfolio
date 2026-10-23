import 'package:flutter/material.dart';

import 'inset_shadow.dart';
import 'tokens.dart';

enum NeuShape { flat, convex, concave, pressed }

/// Switches surfaces to a flat, shadow-free variant (long lists, web performance).
class NeuScope extends InheritedWidget {
  const NeuScope({super.key, required this.reduced, required super.child});

  final bool reduced;

  static bool reducedOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<NeuScope>()?.reduced ?? false;

  @override
  bool updateShouldNotify(NeuScope old) => old.reduced != reduced;
}

/// The basic neumorphic building block: a surface that is raised, inset or flat.
class NeuSurface extends StatelessWidget {
  const NeuSurface({
    super.key,
    this.child,
    this.shape = NeuShape.convex,
    this.depth = 2,
    this.radius = NeuTheme.radiusM,
    this.padding,
    this.color,
    this.width,
    this.height,
    this.border,
    this.alignment,
    this.constraints,
    this.circle = false,
  });

  final Widget? child;
  final NeuShape shape;
  final int depth;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? width;
  final double? height;
  final Border? border;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final reduced = NeuScope.reducedOf(context);
    final br = BorderRadius.circular(radius);
    final inset = shape == NeuShape.concave || shape == NeuShape.pressed;
    final base = color ?? (inset ? n.surfaceAlt : n.surface);

    Border? effectiveBorder = border;
    List<BoxShadow> shadows = const [];
    Gradient? gradient;

    if (reduced || shape == NeuShape.flat) {
      effectiveBorder ??= Border.all(color: n.outline);
    } else if (shape == NeuShape.convex) {
      shadows = n.raised(depth);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(base, n.highlight, n.isDark ? 0.35 : 0.5)!, Color.lerp(base, n.shadow, n.isDark ? 0.18 : 0.12)!],
      );
    }

    final decoration = BoxDecoration(
      color: gradient == null ? base : null,
      gradient: gradient,
      borderRadius: circle ? null : br,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      boxShadow: shadows,
      border: effectiveBorder,
    );

    Widget content = child ?? const SizedBox.shrink();
    // widthFactor/heightFactor keep the surface shrink-wrapped under loose constraints
    // while still aligning the child inside tight (explicit width/height) ones.
    if (alignment != null) content = Align(alignment: alignment!, widthFactor: 1, heightFactor: 1, child: content);
    if (padding != null) content = Padding(padding: padding!, child: content);

    Widget surface = DecoratedBox(decoration: decoration, child: content);
    if (inset && !reduced) {
      surface = CustomPaint(
        foregroundPainter: InsetShadowPainter(
          radius: circle ? BorderRadius.circular(9999) : br,
          shadows: n.inset(shape == NeuShape.pressed ? depth + 1 : depth),
        ),
        child: surface,
      );
    }
    return Container(width: width, height: height, constraints: constraints, child: surface);
  }
}

/// An elevated content card.
class NeuCard extends StatelessWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NeuTheme.s5),
    this.depth = 3,
    this.radius = NeuTheme.radiusL,
    this.onTap,
    this.shape = NeuShape.convex,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final int depth;
  final double radius;
  final VoidCallback? onTap;
  final NeuShape shape;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return NeuSurface(shape: shape, depth: depth, radius: radius, padding: padding, child: child);
    }
    return NeuPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      radius: radius,
      minSize: Size.zero,
      builder: (context, s) => NeuSurface(
        shape: s.pressed ? NeuShape.pressed : shape,
        depth: s.pressed ? 2 : depth,
        radius: radius,
        padding: padding,
        child: child,
      ),
    );
  }
}

class PressState {
  const PressState({this.pressed = false, this.hovered = false, this.focused = false});
  final bool pressed;
  final bool hovered;
  final bool focused;
}

/// Handles tap, hover, keyboard focus/activation and a visible focus ring.
class NeuPressable extends StatefulWidget {
  const NeuPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.semanticLabel,
    this.radius = NeuTheme.radiusM,
    this.minSize = const Size(NeuTheme.minHit, NeuTheme.minHit),
    this.tooltip,
    this.selected,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget Function(BuildContext context, PressState state) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final String? semanticLabel;
  final double radius;
  final Size minSize;
  final String? tooltip;
  final bool? selected;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<NeuPressable> createState() => _NeuPressableState();
}

class _NeuPressableState extends State<NeuPressable> {
  bool _pressed = false, _hovered = false, _focused = false;

  bool get _enabled => widget.onTap != null;

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    Widget w = widget.builder(context, PressState(pressed: _pressed, hovered: _hovered, focused: _focused));
    w = Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        w,
        if (_focused)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius + 3),
                  border: Border.all(color: n.accent, width: 2),
                ),
              ),
            ),
          ),
      ],
    );
    w = ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minSize.width, minHeight: widget.minSize.height),
      child: w,
    );
    w = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => _set(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => _set(() => _pressed = false) : null,
      onTapCancel: _enabled ? () => _set(() => _pressed = false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onSecondaryTap: widget.onSecondaryTap,
      child: w,
    );
    w = FocusableActionDetector(
      enabled: _enabled,
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (v) => _set(() => _hovered = v),
      onShowFocusHighlight: (v) => _set(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: w,
    );
    w = Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      child: w,
    );
    if (widget.tooltip != null) w = Tooltip(message: widget.tooltip!, child: w);
    return w;
  }
}

import 'package:flutter/cupertino.dart';

import 'cu_section.dart';
import 'cupertino_theme.dart';

/// A rounded grouped-background container (the Cupertino counterpart of a card or well).
class CuSurface extends StatelessWidget {
  const CuSurface({
    super.key,
    this.child,
    this.radius,
    this.padding,
    this.color,
    this.width,
    this.height,
    this.border,
    this.alignment,
    this.constraints,
    this.circle = false,
    this.inset = false,
  });

  final Widget? child;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? width;
  final double? height;
  final Border? border;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final bool circle;

  /// Uses the quiet fill color (text-field wells) instead of the grouped row background.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final flat = inset && CuSectionScope.of(context);
    return Container(
      width: width,
      height: height,
      alignment: alignment ?? (flat ? Alignment.centerRight : null),
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: flat ? null : (color ?? (inset ? p.fill : p.secondaryGroupedBackground)),
        border: border,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius ?? CupertinoMetrics.current.groupRadius),
      ),
      child: child,
    );
  }
}

/// Interaction state for [CuPressable].
class CuPressState {
  const CuPressState({this.pressed = false, this.hovered = false, this.focused = false});
  final bool pressed;
  final bool hovered;
  final bool focused;
}

/// A focusable, hoverable, pressable region (pointer and keyboard).
class CuPressable extends StatefulWidget {
  const CuPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.semanticLabel,
    this.minSize,
    this.selected,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget Function(BuildContext context, CuPressState state) builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final String? semanticLabel;
  final Size? minSize;
  final bool? selected;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<CuPressable> createState() => _CuPressableState();
}

class _CuPressableState extends State<CuPressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  void _set(void Function() f) {
    if (mounted) setState(f);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => _set(() => _hovered = v),
        onShowFocusHighlight: (v) => _set(() => _focused = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(() => _pressed = true) : null,
          onTapCancel: () => _set(() => _pressed = false),
          onTapUp: (_) => _set(() => _pressed = false),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onSecondaryTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: (widget.minSize ?? Size.square(CupertinoMetrics.current.minHit)).width,
              minHeight: (widget.minSize ?? Size.square(CupertinoMetrics.current.minHit)).height,
            ),
            child: widget.builder(context, CuPressState(pressed: _pressed && enabled, hovered: _hovered, focused: _focused)),
          ),
        ),
      ),
    );
  }
}

/// A plain tappable region with the standard pressed fade.
class CuTappable extends StatefulWidget {
  const CuTappable({super.key, required this.child, this.onTap, this.onLongPress});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<CuTappable> createState() => _CuTappableState();
}

class _CuTappableState extends State<CuTappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedOpacity(duration: const Duration(milliseconds: 80), opacity: _pressed ? 0.55 : 1, child: widget.child),
    ),
  );
}

/// A hairline separator.
class CuDivider extends StatelessWidget {
  const CuDivider({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: Center(
      child: ColoredBox(
        color: CupertinoPalette.of(context).separator,
        child: const SizedBox(height: 0.5, width: double.infinity),
      ),
    ),
  );
}

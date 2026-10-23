import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_surface.dart';
import '../neu/neu_surface.dart';
import '../neu/tokens.dart';
import 'app_theme.dart';
import 'skin_scope.dart';

/// How a surface sits relative to its background.
enum AppShape { flat, raised, inset, pressed }

NeuShape _neuShape(AppShape s) => switch (s) {
  AppShape.flat => NeuShape.flat,
  AppShape.raised => NeuShape.convex,
  AppShape.inset => NeuShape.concave,
  AppShape.pressed => NeuShape.pressed,
};

/// Switches surfaces to a flat, shadow-free variant (long lists, web performance).
class AppSurfaceScope extends StatelessWidget {
  const AppSurfaceScope({super.key, required this.reduced, required this.child});

  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) => NeuScope(reduced: reduced, child: child);
}

/// A rounded surface: raised, inset or flat. The generic container of both skins.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    this.child,
    this.shape = AppShape.raised,
    this.depth = 2,
    this.radius = AppSpace.radiusM,
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
  final AppShape shape;
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
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuSurface(
      shape: _neuShape(shape),
      depth: depth,
      radius: radius,
      padding: padding,
      color: color,
      width: width,
      height: height,
      border: border,
      alignment: alignment,
      constraints: constraints,
      circle: circle,
      child: child,
    ),
    AppSkin.cupertino => CuSurface(
      inset: shape == AppShape.inset,
      radius: radius > 14 ? null : radius,
      padding: padding,
      color: color,
      width: width,
      height: height,
      border: border,
      alignment: alignment,
      constraints: constraints,
      circle: circle,
      child: child,
    ),
  };
}

/// A content block (chart, summary, form group). Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.s5),
    this.depth = 3,
    this.radius = AppSpace.radiusL,
    this.onTap,
    this.shape = AppShape.raised,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final int depth;
  final double radius;
  final VoidCallback? onTap;
  final AppShape shape;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuCard(
      padding: padding,
      depth: depth,
      radius: radius,
      onTap: onTap,
      shape: _neuShape(shape),
      semanticLabel: semanticLabel,
      child: child,
    ),
    AppSkin.cupertino => _cupertinoCard(),
  };

  Widget _cupertinoCard() {
    final surface = CuSurface(padding: padding, radius: radius > 14 ? null : radius, inset: shape == AppShape.inset, child: child);
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: CuTappable(onTap: onTap, child: surface),
    );
  }
}

/// Interaction state handed to an [AppPressable] builder.
class AppPressState {
  const AppPressState({this.pressed = false, this.hovered = false, this.focused = false});
  final bool pressed;
  final bool hovered;
  final bool focused;
}

/// A focusable, hoverable, pressable region with pointer and keyboard support.
class AppPressable extends StatelessWidget {
  const AppPressable({
    super.key,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.semanticLabel,
    this.radius = AppSpace.radiusM,
    this.minSize = const Size(AppSpace.minHit, AppSpace.minHit),
    this.tooltip,
    this.selected,
    this.autofocus = false,
    this.focusNode,
  });

  final Widget Function(BuildContext context, AppPressState state) builder;
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
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      semanticLabel: semanticLabel,
      radius: radius,
      minSize: minSize,
      tooltip: tooltip,
      selected: selected,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (context, s) => builder(context, AppPressState(pressed: s.pressed, hovered: s.hovered, focused: s.focused)),
    ),
    AppSkin.cupertino => CuPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      semanticLabel: semanticLabel,
      minSize: minSize == const Size(AppSpace.minHit, AppSpace.minHit) ? null : minSize,
      selected: selected,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (context, s) => builder(context, AppPressState(pressed: s.pressed, hovered: s.hovered, focused: s.focused)),
    ),
  };
}

/// A thin separator line.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = 1});

  final double height;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => SizedBox(
      height: height,
      child: Center(
        child: ColoredBox(
          color: NeuTheme.of(context).outline,
          child: const SizedBox(height: 1, width: double.infinity),
        ),
      ),
    ),
    AppSkin.cupertino => const CuDivider(),
  };
}

/// Transparent ink host for stock widgets that need a [Material] ancestor (for example reorderable lists).
class AppMaterialHost extends StatelessWidget {
  const AppMaterialHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(type: MaterialType.transparency, child: child);
}

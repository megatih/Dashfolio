import 'package:flutter/material.dart' show IconButton, TextButton;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_buttons.dart';
import '../neu/neu_button.dart';
import 'app_icons.dart';
import 'app_theme.dart';
import 'skin_scope.dart';

enum AppButtonKind { normal, primary, danger }

NeuButtonKind _neuKind(AppButtonKind k) => switch (k) {
  AppButtonKind.normal => NeuButtonKind.normal,
  AppButtonKind.primary => NeuButtonKind.primary,
  AppButtonKind.danger => NeuButtonKind.danger,
};

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = AppButtonKind.normal,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIcon? icon;
  final AppButtonKind kind;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => NeuButton(
        label: label,
        onPressed: onPressed,
        icon: icon?.of(skin),
        kind: _neuKind(kind),
        loading: loading,
        expand: expand,
        compact: compact,
      ),
      AppSkin.cupertino => CuButton(
        label: label,
        onPressed: onPressed,
        icon: icon?.of(skin),
        kind: switch (kind) {
          AppButtonKind.normal => CuButtonKind.normal,
          AppButtonKind.primary => CuButtonKind.primary,
          AppButtonKind.danger => CuButtonKind.danger,
        },
        loading: loading,
        expand: expand,
        compact: compact,
      ),
    };
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.size = AppSpace.minHit,
    this.loading = false,
  });

  final AppIcon icon;

  /// Also the semantic label, so it is required.
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => NeuIconButton(
        icon: icon.of(skin),
        tooltip: tooltip,
        onPressed: onPressed,
        selected: selected,
        size: size,
        loading: loading,
      ),
      AppSkin.cupertino => CuIconButton(
        icon: icon.of(skin),
        tooltip: tooltip,
        onPressed: onPressed,
        selected: selected,
        size: size == AppSpace.minHit ? null : size,
        loading: loading,
      ),
    };
  }
}

/// A low-emphasis, text-only button (dialog actions, inline links).
class AppTextButton extends StatelessWidget {
  const AppTextButton({super.key, required this.label, this.onPressed, this.icon, this.destructive = false});

  final String label;
  final VoidCallback? onPressed;
  final AppIcon? icon;

  /// Colours the label as a destructive action.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    if (skin == AppSkin.cupertino) {
      return CuTextButton(label: label, onPressed: onPressed, icon: icon?.of(skin), destructive: destructive);
    }
    final style = destructive ? TextButton.styleFrom(foregroundColor: context.app.loss) : null;
    return icon == null
        ? TextButton(onPressed: onPressed, style: style, child: Text(label))
        : TextButton.icon(onPressed: onPressed, style: style, icon: AppIconView(icon!, size: 18), label: Text(label));
  }
}

/// A borderless icon button for dense rows (no raised surface).
class AppInlineIconButton extends StatelessWidget {
  const AppInlineIconButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.size = 18, this.color});

  final AppIcon icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => IconButton(
        tooltip: tooltip,
        icon: AppIconView(icon, size: size, color: color),
        onPressed: onPressed,
      ),
      AppSkin.cupertino => CuIconButton(
        icon: icon.of(skin),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: size,
        color: color,
        size: 36,
      ),
    };
  }
}

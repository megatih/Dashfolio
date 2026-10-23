import 'package:flutter/cupertino.dart';

import 'cupertino_theme.dart';

enum CuButtonKind { normal, primary, danger }

/// Marks the action row of an alert: buttons inside render as edge-to-edge alert actions (default bold, destructive red).
class CuActionScope extends InheritedWidget {
  const CuActionScope({super.key, required super.child});

  static bool of(BuildContext context) => context.getInheritedWidgetOfExactType<CuActionScope>() != null;

  @override
  bool updateShouldNotify(CuActionScope oldWidget) => false;
}

class _AlertAction extends StatelessWidget {
  const _AlertAction({required this.label, required this.onPressed, this.bold = false, this.destructive = false});

  final String label;
  final VoidCallback? onPressed;
  final bool bold;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final color = onPressed == null ? p.tertiaryLabel : (destructive ? p.loss : p.accent);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size(double.infinity, m.pointer ? 32 : m.minHit),
        onPressed: onPressed,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (bold ? t.headline : t.body).copyWith(color: color),
        ),
      ),
    );
  }
}

/// A capsule button: filled (primary), tinted (normal) or red-tinted (danger). Destructive is never a solid red fill.
class CuButton extends StatelessWidget {
  const CuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.kind = CuButtonKind.normal,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CuButtonKind kind;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final m = CupertinoMetrics.current;
    final t = CupertinoTypography.of(context);
    final enabled = onPressed != null && !loading;
    if (CuActionScope.of(context)) {
      return _AlertAction(
        label: label,
        onPressed: enabled ? onPressed : null,
        bold: kind == CuButtonKind.primary,
        destructive: kind == CuButtonKind.danger,
      );
    }
    final filled = kind == CuButtonKind.primary;
    // On macOS a plain push button is neutral gray; elsewhere it takes the tint.
    final tint = switch (kind) {
      CuButtonKind.danger => p.loss,
      CuButtonKind.normal when m.pointer => p.label,
      _ => p.accent,
    };
    final fg = filled ? p.onAccent : tint;
    final style = (m.pointer ? t.body : t.callout.copyWith(fontWeight: FontWeight.w600)).copyWith(color: enabled ? fg : p.tertiaryLabel);
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          CupertinoActivityIndicator(radius: m.iconSize / 2, color: fg)
        else if (icon != null)
          Icon(icon, size: m.iconSize, color: enabled ? fg : p.tertiaryLabel),
        if (loading || icon != null) const SizedBox(width: 6),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
    final height = compact
        ? m.controlHeight
        : (expand && !m.pointer ? m.largeControlHeight : (m.pointer ? m.largeControlHeight : m.minHit));
    final size = Size(compact ? 0 : m.minHit, height);
    final padding = EdgeInsets.symmetric(horizontal: compact ? 12 : (m.pointer ? 14 : 20));
    final handler = enabled ? onPressed : null;
    final radius = BorderRadius.circular(height);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: handler,
      child: switch (kind) {
        CuButtonKind.primary => CupertinoButton.filled(
          onPressed: handler,
          padding: padding,
          minimumSize: size,
          borderRadius: radius,
          child: child,
        ),
        _ => CupertinoButton.tinted(
          onPressed: handler,
          padding: padding,
          minimumSize: size,
          borderRadius: radius,
          color: tint,
          child: child,
        ),
      },
    );
  }
}

class CuIconButton extends StatelessWidget {
  const CuIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.size,
    this.iconSize,
    this.color,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  /// Hit size; defaults to the platform minimum.
  final double? size;
  final double? iconSize;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final m = CupertinoMetrics.current;
    final enabled = onPressed != null && !loading;
    final hit = size ?? (m.pointer ? 28 : m.minHit);
    final symbol = iconSize ?? m.navIconSize;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.square(hit),
        onPressed: enabled ? onPressed : null,
        child: loading
            ? CupertinoActivityIndicator(radius: symbol / 2.4)
            : Icon(icon, size: symbol, color: color ?? (enabled ? p.accent : p.tertiaryLabel)),
      ),
    );
  }
}

/// A text-only button (dialog actions, inline links).
class CuTextButton extends StatelessWidget {
  const CuTextButton({super.key, required this.label, this.onPressed, this.icon, this.destructive = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final m = CupertinoMetrics.current;
    final t = CupertinoTypography.of(context);
    if (CuActionScope.of(context)) return _AlertAction(label: label, onPressed: onPressed, destructive: destructive);
    final color = onPressed == null ? p.tertiaryLabel : (destructive ? p.loss : p.accent);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size(0, m.minHit),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: m.iconSize, color: color), const SizedBox(width: 4)],
            Flexible(
              child: Text(label, style: t.body.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

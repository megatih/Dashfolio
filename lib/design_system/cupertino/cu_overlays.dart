import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import 'cu_buttons.dart';
import 'cu_menu.dart';
import 'cu_section.dart';
import 'cupertino_theme.dart';

/// Shows a dialog route built by [builder] on the root navigator.
Future<T?> showCuModal<T>(BuildContext context, {required WidgetBuilder builder, Color? barrierColor, bool barrierDismissible = true}) =>
    showCupertinoDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? kCupertinoModalBarrierColor,
    );

/// An alert-style dialog: a centred title, free-form content, and actions side by side (two) or stacked (more), separated by
/// hairlines. Buttons passed as [actions] render as alert actions.
class CuDialog extends StatelessWidget {
  const CuDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.maxWidth = 520,
    this.scrollable = true,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    Widget hairline({bool vertical = false}) => SizedBox(
      width: vertical ? 0.5 : null,
      height: vertical ? null : 0.5,
      child: ColoredBox(color: p.separator),
    );
    final Widget? actionBar = actions.isEmpty
        ? null
        : CuActionScope(
            child: actions.length == 2
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: actions[0]),
                        hairline(vertical: true),
                        Expanded(child: actions[1]),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, a) in actions.indexed) ...[if (i > 0) hairline(), a],
                    ],
                  ),
          );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, m.pointer ? 16 : 20, 20, 12),
          child: Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: t.headline),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        ),
        if (actionBar != null) ...[hairline(), actionBar],
      ],
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth.clamp(270, m.pointer ? 420 : 520).toDouble()),
          child: CupertinoPopupSurface(
            child: DefaultTextStyle(style: t.body, child: body),
          ),
        ),
      ),
    );
  }
}

Future<T?> showCuDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  List<Widget> actions = const [],
  double maxWidth = 520,
}) => showCuModal<T>(
  context,
  builder: (_) => CuDialog(title: title, actions: actions, maxWidth: maxWidth, child: child),
);

Future<bool> showCuConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(padding: const EdgeInsets.only(top: 6), child: Text(message)),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A form or detail sheet: a page sheet on compact widths, a centred form sheet when wide. [builder] normally returns a
/// `CuSheetScaffold`.
Future<T?> showCuSheet<T>(BuildContext context, {required WidgetBuilder builder, double maxWidth = 560, required double dialogBreakpoint}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= dialogBreakpoint) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth.clamp(0, 560).toDouble(), maxHeight: MediaQuery.sizeOf(ctx).height * 0.88),
            child: CupertinoPopupSurface(
              child: _SheetBody(child: CuSheetShape(builder: builder)),
            ),
          ),
        ),
      ),
    );
  }
  return Navigator.of(context, rootNavigator: true).push(
    CupertinoSheetRoute<T>(
      scrollableBuilder: (ctx, _) => _SheetBody(child: CuSheetShape(builder: builder)),
    ),
  );
}

/// Gives a sheet's content its background and a [Navigator] context of its own.
class CuSheetShape extends StatelessWidget {
  const CuSheetShape({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CupertinoPalette.of(context).groupedBackground,
    child: DefaultTextStyle(style: CupertinoTypography.of(context).body, child: child),
  );
}

/// The frame of a form sheet: Cancel on the left, the title in the middle and the confirm action on the right in bold, above
/// a scrolling body. Pass children that are [CuSection]s for the usual grouped form.
class CuSheetScaffold extends StatelessWidget {
  const CuSheetScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onCancel,
    this.confirmLabel,
    this.onConfirm,
    this.busy = false,
    this.cancelLabel = 'Cancel',
    this.destructiveLabel,
    this.onDestructive,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onCancel;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final bool busy;
  final String cancelLabel;

  /// A destructive action (for example Delete), shown as its own red row below the form.
  final String? destructiveLabel;
  final VoidCallback? onDestructive;

  /// Extra content below the form (for example a validation summary).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final pad = CupertinoMetrics.inset;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: m.pointer ? 48 : 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CuTextButton(label: cancelLabel, onPressed: onCancel ?? () => Navigator.of(context).pop()),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(title, style: t.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: busy
                        ? const Padding(padding: EdgeInsets.only(right: 12), child: CupertinoActivityIndicator())
                        : confirmLabel == null
                        ? const SizedBox.shrink()
                        : Semantics(
                            button: true,
                            enabled: onConfirm != null,
                            label: confirmLabel,
                            excludeSemantics: true,
                            onTap: onConfirm,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: Size(0, m.minHit),
                              onPressed: onConfirm,
                              child: Text(confirmLabel!, style: t.headline.copyWith(color: onConfirm == null ? p.tertiaryLabel : p.accent)),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 0.5, child: ColoredBox(color: p.separator)),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: CupertinoMetrics.sectionGap), c],
                if (destructiveLabel != null) ...[
                  const SizedBox(height: CupertinoMetrics.sectionGap),
                  CuSection(
                    children: [CuActionRow(label: destructiveLabel!, destructive: true, onTap: onDestructive)],
                  ),
                ],
                if (footer != null) ...[const SizedBox(height: 12), footer!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// An icon button that opens a pull-down menu of actions.
class CuMenuButton<T> extends StatelessWidget {
  const CuMenuButton({super.key, required this.items, required this.onSelected, required this.tooltip, required this.icon, this.iconColor});

  final List<CuMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => CuPopupMenu<T>(
    items: items,
    onSelected: onSelected,
    builder: (context, open) => CuIconButton(icon: icon, tooltip: tooltip, color: iconColor, onPressed: open),
  );
}

OverlayEntry? _toast;

/// A short banner at the top of the screen that dismisses itself.
void showCuToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toast?.remove();
  late final OverlayEntry entry;
  void dismiss() {
    if (_toast == entry) _toast = null;
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _Toast(message: message, error: error, onDismiss: dismiss),
  );
  _toast = entry;
  overlay.insert(entry);
}

/// Owns the dismiss timer so it is cancelled with the widget, including when the whole tree goes away.
class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.error, required this.onDismiss});

  final String message;
  final bool error;
  final VoidCallback onDismiss;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  late final Timer _timer = Timer(const Duration(seconds: 4), widget.onDismiss);

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final bottom = CupertinoMetrics.current.pointer;
    return SafeArea(
      child: Align(
        alignment: bottom ? Alignment.bottomCenter : Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Semantics(
                liveRegion: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.error ? p.loss.withValues(alpha: 0.92) : p.barBackground,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: p.separator, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Text(widget.message, style: t.subheadline.copyWith(color: widget.error ? p.onAccent : p.label)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CuTooltip extends StatelessWidget {
  const CuTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(tooltip: message, child: child);
}

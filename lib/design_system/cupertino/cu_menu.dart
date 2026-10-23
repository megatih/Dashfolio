import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'cupertino_theme.dart';

class CuMenuItem<T> {
  const CuMenuItem(this.value, this.label, {this.destructive = false, this.checked});
  final T value;
  final String label;
  final bool destructive;

  /// Non-null shows a checkmark column; true marks this item as the current choice.
  final bool? checked;
}

/// A pull-down menu anchored to the widget built by [builder] (call the given callback to open it). Destructive items are
/// separated from the rest and red, as on Apple platforms.
class CuPopupMenu<T> extends StatelessWidget {
  const CuPopupMenu({super.key, required this.items, required this.onSelected, required this.builder, this.enabled = true});

  final List<CuMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext context, VoidCallback open) builder;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = CupertinoTypography.of(context);
    final p = CupertinoPalette.of(context);
    final m = CupertinoMetrics.current;
    final anyChecked = items.any((i) => i.checked != null);
    final children = <Widget>[];
    var previousDestructive = false;
    for (final (index, i) in items.indexed) {
      if (index > 0 && i.destructive && !previousDestructive) children.add(const CupertinoMenuDivider());
      previousDestructive = i.destructive;
      children.add(
        CupertinoMenuItem(
          isDestructiveAction: i.destructive,
          leading: anyChecked ? (i.checked == true ? Icon(CupertinoIcons.check_mark, size: m.iconSize, color: p.label) : null) : null,
          onPressed: () => onSelected(i.value),
          child: Text(i.label, style: t.body.copyWith(color: i.destructive ? p.loss : p.label)),
        ),
      );
    }
    return CupertinoMenuAnchor(
      useRootOverlay: true,
      constrainCrossAxis: true,
      menuChildren: children,
      builder: (context, controller, _) =>
          builder(context, enabled ? () => controller.isOpen ? controller.close() : controller.open() : () {}),
    );
  }
}

/// Opens a menu at [position] (a pointer or long-press location in global coordinates); resolves to the chosen value, or null
/// when dismissed.
Future<T?> showCuMenu<T>(BuildContext context, {required Offset position, required List<CuMenuItem<T>> items}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future.value();
  final done = Completer<T?>();
  late final OverlayEntry entry;
  void finish(T? value) {
    if (!done.isCompleted) done.complete(value);
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _PositionedMenu<T>(items: items, position: position, onDone: finish),
  );
  overlay.insert(entry);
  return done.future;
}

class _PositionedMenu<T> extends StatefulWidget {
  const _PositionedMenu({required this.items, required this.position, required this.onDone});

  final List<CuMenuItem<T>> items;
  final Offset position;
  final ValueChanged<T?> onDone;

  @override
  State<_PositionedMenu<T>> createState() => _PositionedMenuState<T>();
}

class _PositionedMenuState<T> extends State<_PositionedMenu<T>> {
  final _controller = MenuController();
  T? _chosen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.open(position: widget.position);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = CupertinoTypography.of(context);
    final p = CupertinoPalette.of(context);
    final children = <Widget>[];
    var previousDestructive = false;
    for (final (index, i) in widget.items.indexed) {
      if (index > 0 && i.destructive && !previousDestructive) children.add(const CupertinoMenuDivider());
      previousDestructive = i.destructive;
      children.add(
        CupertinoMenuItem(
          isDestructiveAction: i.destructive,
          onPressed: () => _chosen = i.value,
          child: Text(i.label, style: t.body.copyWith(color: i.destructive ? p.loss : p.label)),
        ),
      );
    }
    return Positioned.fill(
      child: CupertinoMenuAnchor(
        controller: _controller,
        useRootOverlay: true,
        onClose: () => widget.onDone(_chosen),
        menuChildren: children,
        child: const SizedBox.expand(),
      ),
    );
  }
}

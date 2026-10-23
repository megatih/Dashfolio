import 'package:flutter/material.dart' show CheckedPopupMenuItem, PopupMenuButton, PopupMenuEntry, PopupMenuItem, showMenu;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_menu.dart';
import '../cupertino/cu_overlays.dart';
import 'app_icons.dart';
import 'skin_scope.dart';

/// One entry of a popup menu.
class AppMenuItem<T> {
  const AppMenuItem(this.value, this.label, {this.destructive = false, this.checked});
  final T value;
  final String label;
  final bool destructive;

  /// Null for a plain item; otherwise the item shows a check mark when true.
  final bool? checked;
}

PopupMenuEntry<T> _entry<T>(AppMenuItem<T> i) => i.checked == null
    ? PopupMenuItem<T>(value: i.value, child: Text(i.label))
    : CheckedPopupMenuItem<T>(value: i.value, checked: i.checked!, child: Text(i.label));

List<CuMenuItem<T>> _cuItems<T>(List<AppMenuItem<T>> items) => [
  for (final i in items) CuMenuItem<T>(i.value, i.label, destructive: i.destructive, checked: i.checked),
];

/// An icon button that opens a menu of actions.
class AppMenuButton<T> extends StatelessWidget {
  const AppMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    required this.tooltip,
    this.icon = AppIcon.moreVertical,
    this.iconColor,
  });

  final List<AppMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final AppIcon icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => PopupMenuButton<T>(
        tooltip: tooltip,
        icon: AppIconView(icon, color: iconColor),
        onSelected: onSelected,
        itemBuilder: (_) => [for (final i in items) _entry(i)],
      ),
      AppSkin.cupertino => CuMenuButton<T>(
        items: _cuItems(items),
        onSelected: onSelected,
        tooltip: tooltip,
        icon: icon.of(skin),
        iconColor: iconColor,
      ),
    };
  }
}

/// Opens a context menu at a pointer position and returns the chosen value.
Future<T?> showAppMenu<T>(BuildContext context, {required Offset position, required List<AppMenuItem<T>> items}) =>
    switch (AppSkinScope.of(context)) {
      AppSkin.neumorphic => showMenu<T>(
        context: context,
        position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        items: [for (final i in items) _entry(i)],
      ),
      AppSkin.cupertino => showCuMenu<T>(context, position: position, items: _cuItems(items)),
    };

import 'package:flutter/material.dart' show DataColumn, DataRow, DataCell, DataTable, InkWell, ListTile, ReorderableListView;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_states.dart';
import '../cupertino/cu_surface.dart';
import 'app_surface.dart';
import 'skin_scope.dart';

/// A tappable row: leading, title/subtitle, trailing.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleStyle,
    this.subtitleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading,
      title: Text(title, style: titleStyle),
      subtitle: subtitle == null ? null : Text(subtitle!, style: subtitleStyle),
      trailing: trailing,
      onTap: onTap,
    ),
    AppSkin.cupertino => CuRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    ),
  };
}

/// A non-scrolling list whose rows can be dragged to reorder (start a drag with `ReorderableDragStartListener`).
/// Every item needs a unique key. [onReorder] receives the final index after the move.
class AppReorderableList extends StatelessWidget {
  const AppReorderableList({super.key, required this.itemCount, required this.itemBuilder, required this.onReorder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) => ReorderableListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    buildDefaultDragHandles: false,
    itemCount: itemCount,
    onReorderItem: onReorder,
    proxyDecorator: (child, index, animation) => AppMaterialHost(child: child),
    itemBuilder: itemBuilder,
  );
}

/// A plain tappable region (no surface): rows inside lists and tables.
class AppTappable extends StatelessWidget {
  const AppTappable({super.key, required this.child, this.onTap, this.onLongPress});

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => InkWell(onTap: onTap, onLongPress: onLongPress, child: child),
    AppSkin.cupertino => CuTappable(onTap: onTap, onLongPress: onLongPress, child: child),
  };
}

/// A small read-only grid of text: a header row and string rows (previews of imported files).
class AppSimpleTable extends StatelessWidget {
  const AppSimpleTable({super.key, required this.headers, required this.rows, this.headerStyle, this.cellStyle});

  final List<String> headers;
  final List<List<String>> rows;
  final TextStyle? headerStyle;
  final TextStyle? cellStyle;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 36,
        columns: [for (final h in headers) DataColumn(label: Text(h, style: headerStyle))],
        rows: [
          for (final r in rows)
            DataRow(cells: [for (var i = 0; i < headers.length; i++) DataCell(Text(i < r.length ? r[i] : '', style: cellStyle))]),
        ],
      ),
    ),
    AppSkin.cupertino => CuSimpleTable(headers: headers, rows: rows, headerStyle: headerStyle, cellStyle: cellStyle),
  };
}

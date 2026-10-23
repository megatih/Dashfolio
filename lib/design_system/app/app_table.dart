import 'package:flutter/widgets.dart';

import '../cupertino/cu_table.dart';
import '../neu/neu_data_table.dart';
import 'skin_scope.dart';

class AppColumn<T> {
  const AppColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.width = 110,
    this.flex,
    this.numeric = false,
    this.sortable = true,
    this.alwaysShow = false,
  });

  final String id;
  final String label;
  final Widget Function(BuildContext context, T row) cell;
  final double width;
  final int? flex;
  final bool numeric;
  final bool sortable;

  /// Kept when the table narrows and other columns are dropped.
  final bool alwaysShow;
}

class AppTable<T> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnId,
    this.ascending = false,
    this.onSort,
    this.onRowTap,
    this.onRowSecondaryTap,
    this.rowSemanticLabel,
    this.emptyMessage = 'Nothing to show',
    this.rowHeight = 56,
  });

  final List<AppColumn<T>> columns;
  final List<T> rows;
  final String? sortColumnId;
  final bool ascending;
  final void Function(String columnId, bool ascending)? onSort;
  final ValueChanged<T>? onRowTap;
  final void Function(T row, Offset globalPosition)? onRowSecondaryTap;
  final String Function(T row)? rowSemanticLabel;
  final String emptyMessage;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuDataTable<T>(
      columns: [
        for (final c in columns)
          NeuColumn<T>(
            id: c.id,
            label: c.label,
            cell: c.cell,
            width: c.width,
            flex: c.flex,
            numeric: c.numeric,
            sortable: c.sortable,
            alwaysShow: c.alwaysShow,
          ),
      ],
      rows: rows,
      sortColumnId: sortColumnId,
      ascending: ascending,
      onSort: onSort,
      onRowTap: onRowTap,
      onRowSecondaryTap: onRowSecondaryTap,
      rowSemanticLabel: rowSemanticLabel,
      emptyMessage: emptyMessage,
      rowHeight: rowHeight,
    ),
    AppSkin.cupertino => CuTable<T>(
      columns: [
        for (final c in columns)
          CuColumn<T>(id: c.id, label: c.label, cell: c.cell, width: c.width, flex: c.flex, numeric: c.numeric, sortable: c.sortable),
      ],
      rows: rows,
      sortColumnId: sortColumnId,
      ascending: ascending,
      onSort: onSort,
      onRowTap: onRowTap,
      onRowSecondaryTap: onRowSecondaryTap,
      rowSemanticLabel: rowSemanticLabel,
      emptyMessage: emptyMessage,
      rowHeight: rowHeight,
    ),
  };
}

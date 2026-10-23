import 'package:flutter/cupertino.dart';

import 'cupertino_theme.dart';

class CuColumn<T> {
  const CuColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.width = 110,
    this.flex,
    this.numeric = false,
    this.sortable = true,
  });

  final String id;
  final String label;
  final Widget Function(BuildContext context, T row) cell;
  final double width;
  final int? flex;
  final bool numeric;
  final bool sortable;
}

/// Aligned-column list with a sortable header row. Scrolls horizontally when the columns need more room.
class CuTable<T> extends StatelessWidget {
  const CuTable({
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
    this.rowHeight,
  });

  final List<CuColumn<T>> columns;
  final List<T> rows;
  final String? sortColumnId;
  final bool ascending;
  final void Function(String columnId, bool ascending)? onSort;
  final ValueChanged<T>? onRowTap;
  final void Function(T row, Offset globalPosition)? onRowSecondaryTap;
  final String Function(T row)? rowSemanticLabel;
  final String emptyMessage;
  final double? rowHeight;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final m = CupertinoMetrics.current;
    final rowH = rowHeight ?? (m.pointer ? 32.0 : 56.0);
    return LayoutBuilder(
      builder: (context, c) {
        final minWidth = columns.fold<double>(0, (s, e) => s + e.width);
        final tableWidth = c.maxWidth.isFinite ? (c.maxWidth > minWidth ? c.maxWidth : minWidth) : minWidth;
        final flexTotal = columns.fold<int>(0, (s, e) => s + (e.flex ?? 0));
        final extra = tableWidth - minWidth;
        double widthOf(CuColumn<T> col) => col.width + (flexTotal == 0 || col.flex == null ? 0 : extra * col.flex! / flexTotal);

        final header = Container(
          height: m.pointer ? 28 : 36,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.separator, width: 0.5)),
          ),
          child: Row(
            children: [
              for (final col in columns)
                SizedBox(
                  width: widthOf(col),
                  child: _Header<T>(
                    col: col,
                    active: sortColumnId == col.id,
                    ascending: ascending,
                    onSort: col.sortable && onSort != null ? () => onSort!(col.id, sortColumnId == col.id ? !ascending : false) : null,
                  ),
                ),
            ],
          ),
        );

        final body = rows.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(emptyMessage, style: t.subheadline)),
              )
            : Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    SizedBox(
                      height: rowH,
                      child: _Row<T>(
                        row: rows[i],
                        columns: columns,
                        widthOf: widthOf,
                        last: i == rows.length - 1,
                        onTap: onRowTap == null ? null : () => onRowTap!(rows[i]),
                        onSecondaryTap: onRowSecondaryTap == null ? null : (pos) => onRowSecondaryTap!(rows[i], pos),
                        label: rowSemanticLabel?.call(rows[i]),
                      ),
                    ),
                ],
              );

        final table = SizedBox(
          width: tableWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [header, body]),
        );
        if (tableWidth <= c.maxWidth + 0.5) return table;
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
      },
    );
  }
}

class _Header<T> extends StatelessWidget {
  const _Header({required this.col, required this.active, required this.ascending, this.onSort});

  final CuColumn<T> col;
  final bool active;
  final bool ascending;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    final t = CupertinoTypography.of(context);
    final color = active ? p.accent : p.secondaryLabel;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: col.numeric ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              col.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.caption1.copyWith(fontWeight: FontWeight.w600, color: color),
            ),
          ),
          if (active) Icon(ascending ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down, size: 12, color: color),
        ],
      ),
    );
    if (onSort == null) return content;
    return Semantics(
      button: true,
      label: 'Sort by ${col.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSort,
        child: Align(alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft, child: content),
      ),
    );
  }
}

class _Row<T> extends StatefulWidget {
  const _Row({
    required this.row,
    required this.columns,
    required this.widthOf,
    required this.last,
    this.onTap,
    this.onSecondaryTap,
    this.label,
  });

  final T row;
  final List<CuColumn<T>> columns;
  final double Function(CuColumn<T>) widthOf;
  final bool last;
  final VoidCallback? onTap;
  final void Function(Offset)? onSecondaryTap;
  final String? label;

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final p = CupertinoPalette.of(context);
    Widget row = Container(
      decoration: BoxDecoration(
        color: _hover || _focus ? p.quaternaryFill : null,
        border: widget.last ? null : Border(bottom: BorderSide(color: p.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          for (final col in widget.columns)
            SizedBox(
              width: widget.widthOf(col),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft, child: col.cell(context, widget.row)),
              ),
            ),
        ],
      ),
    );
    row = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onSecondaryTapUp: widget.onSecondaryTap == null ? null : (d) => widget.onSecondaryTap!(d.globalPosition),
      onLongPressStart: widget.onSecondaryTap == null ? null : (d) => widget.onSecondaryTap!(d.globalPosition),
      child: row,
    );
    return Semantics(
      button: widget.onTap != null,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: row,
      ),
    );
  }
}

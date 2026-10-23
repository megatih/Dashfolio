import 'package:flutter/material.dart';

import 'neu_surface.dart';
import 'tokens.dart';

class NeuColumn<T> {
  const NeuColumn({
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

  /// Minimum / fixed width. When [flex] is set the column grows to fill free space.
  final double width;
  final int? flex;
  final bool numeric;
  final bool sortable;

  /// Kept visible on narrow layouts when columns are collapsed.
  final bool alwaysShow;
}

/// Sortable data table with hover rows, keyboard-focusable rows and context menus.
class NeuDataTable<T> extends StatelessWidget {
  const NeuDataTable({
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

  final List<NeuColumn<T>> columns;
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
  Widget build(BuildContext context) {
    final n = context.neu;
    return LayoutBuilder(
      builder: (context, c) {
        final minWidth = columns.fold<double>(0, (s, e) => s + e.width);
        final tableWidth = c.maxWidth.isFinite ? (c.maxWidth > minWidth ? c.maxWidth : minWidth) : minWidth;
        final flexTotal = columns.fold<int>(0, (s, e) => s + (e.flex ?? 0));
        final extra = tableWidth - minWidth;
        double widthOf(NeuColumn<T> col) => col.width + (flexTotal == 0 || col.flex == null ? 0 : extra * col.flex! / flexTotal);

        Widget header = Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: n.outline)),
          ),
          child: Row(
            children: [
              for (final col in columns)
                SizedBox(
                  width: widthOf(col),
                  child: _HeaderCell<T>(
                    col: col,
                    active: sortColumnId == col.id,
                    ascending: ascending,
                    onSort: col.sortable && onSort != null ? () => onSort!(col.id, sortColumnId == col.id ? !ascending : false) : null,
                  ),
                ),
            ],
          ),
        );

        Widget body = rows.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(NeuTheme.s8),
                child: Center(
                  child: Text(emptyMessage, style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
                ),
              )
            : NeuScope(
                reduced: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows.length,
                  itemExtent: rowHeight,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    return RepaintBoundary(
                      child: _Row<T>(
                        row: row,
                        columns: columns,
                        widthOf: widthOf,
                        striped: i.isOdd,
                        onTap: onRowTap == null ? null : () => onRowTap!(row),
                        onSecondaryTap: onRowSecondaryTap == null ? null : (p) => onRowSecondaryTap!(row, p),
                        label: rowSemanticLabel?.call(row),
                      ),
                    );
                  },
                ),
              );

        final table = SizedBox(
          width: tableWidth,
          child: Column(mainAxisSize: MainAxisSize.min, children: [header, body]),
        );
        if (tableWidth <= c.maxWidth + 0.5) return table;
        return Scrollbar(
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: table),
        );
      },
    );
  }
}

class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({required this.col, required this.active, required this.ascending, this.onSort});

  final NeuColumn<T> col;
  final bool active;
  final bool ascending;
  final VoidCallback? onSort;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final style = context.text.labelMedium!.copyWith(color: active ? n.accent : n.textMuted);
    final content = Row(
      mainAxisAlignment: col.numeric ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(col.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (active) Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: n.accent),
      ],
    );
    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s3),
      child: content,
    );
    if (onSort == null) return padded;
    return Semantics(
      button: true,
      label: 'Sort by ${col.label}',
      child: InkWell(
        onTap: onSort,
        child: Align(alignment: col.numeric ? Alignment.centerRight : Alignment.centerLeft, child: padded),
      ),
    );
  }
}

class _Row<T> extends StatefulWidget {
  const _Row({
    required this.row,
    required this.columns,
    required this.widthOf,
    required this.striped,
    this.onTap,
    this.onSecondaryTap,
    this.label,
  });

  final T row;
  final List<NeuColumn<T>> columns;
  final double Function(NeuColumn<T>) widthOf;
  final bool striped;
  final VoidCallback? onTap;
  final void Function(Offset)? onSecondaryTap;
  final String? label;

  @override
  State<_Row<T>> createState() => _RowState<T>();
}

class _RowState<T> extends State<_Row<T>> {
  bool _hover = false, _focus = false;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final bg = _hover || _focus
        ? n.accent.withValues(alpha: 0.08)
        : (widget.striped ? n.surfaceAlt.withValues(alpha: 0.5) : Colors.transparent);
    Widget row = Container(
      decoration: BoxDecoration(
        color: bg,
        border: _focus ? Border.all(color: n.accent, width: 2) : null,
      ),
      child: Row(
        children: [
          for (final col in widget.columns)
            SizedBox(
              width: widget.widthOf(col),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: NeuTheme.s3),
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

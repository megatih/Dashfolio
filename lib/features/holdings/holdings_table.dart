import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/services/valuation.dart';
import '../common/small_widgets.dart';

enum HoldingSort { symbol, quantity, price, dayPct, value, unrealized, unrealizedPct, weight }

int compareHoldings(HoldingValuation a, HoldingValuation b, HoldingSort sort) {
  int cmpD(Decimal? x, Decimal? y) => (x ?? Decimal.zero).compareTo(y ?? Decimal.zero);
  return switch (sort) {
    HoldingSort.symbol => a.symbol.compareTo(b.symbol),
    HoldingSort.quantity => cmpD(a.quantity, b.quantity),
    HoldingSort.price => (a.priceLocal ?? Decimal.zero).compareTo(b.priceLocal ?? Decimal.zero),
    HoldingSort.dayPct => cmpD(a.dayChangePct, b.dayChangePct),
    HoldingSort.value => cmpD(a.marketValueBase, b.marketValueBase),
    HoldingSort.unrealized => cmpD(a.unrealizedBase, b.unrealizedBase),
    HoldingSort.unrealizedPct => cmpD(a.unrealizedPct, b.unrealizedPct),
    HoldingSort.weight => cmpD(a.weight, b.weight),
  };
}

List<HoldingValuation> sortHoldings(List<HoldingValuation> list, HoldingSort sort, bool ascending) {
  final out = [...list]..sort((a, b) => ascending ? compareHoldings(a, b, sort) : compareHoldings(b, a, sort));
  return out;
}

/// Sortable holdings table; collapses to a two-line list on narrow widths.
class HoldingsTable extends StatefulWidget {
  const HoldingsTable({
    super.key,
    required this.holdings,
    required this.baseCurrency,
    this.onTap,
    this.onAddTransaction,
    this.limit,
    this.emptyMessage = 'No open positions',
  });

  final List<HoldingValuation> holdings;
  final String baseCurrency;
  final ValueChanged<HoldingValuation>? onTap;
  final ValueChanged<HoldingValuation>? onAddTransaction;
  final int? limit;
  final String emptyMessage;

  @override
  State<HoldingsTable> createState() => _HoldingsTableState();
}

class _HoldingsTableState extends State<HoldingsTable> {
  HoldingSort _sort = HoldingSort.value;
  bool _asc = false;

  static HoldingSort _sortFor(String id) => HoldingSort.values.firstWhere((s) => s.name == id);

  Future<void> _menu(HoldingValuation h, Offset pos) async {
    final choice = await showAppMenu<String>(
      context,
      position: pos,
      items: [const AppMenuItem('open', 'View details'), if (widget.onAddTransaction != null) const AppMenuItem('add', 'Add transaction')],
    );
    if (choice == 'open') widget.onTap?.call(h);
    if (choice == 'add') widget.onAddTransaction?.call(h);
  }

  @override
  Widget build(BuildContext context) {
    var rows = sortHoldings(widget.holdings, _sort, _asc);
    if (widget.limit != null && rows.length > widget.limit!) rows = rows.take(widget.limit!).toList();

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          return _CompactList(
            rows: rows,
            currency: widget.baseCurrency,
            onTap: widget.onTap,
            onMenu: _menu,
            emptyMessage: widget.emptyMessage,
          );
        }

        final base = widget.baseCurrency;
        final columns = <AppColumn<HoldingValuation>>[
          AppColumn(
            id: HoldingSort.symbol.name,
            label: 'Symbol',
            width: 150,
            flex: 2,
            cell: (context, h) => Row(
              children: [
                SymbolBadge(h.symbol, size: 34),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.symbol, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(h.name, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppColumn(
            id: HoldingSort.quantity.name,
            label: 'Qty',
            width: 90,
            numeric: true,
            cell: (c, h) => Text(Fmt.number(h.quantity, maxDecimals: 6), style: c.text.bodyMedium),
          ),
          AppColumn(
            id: 'avgCost',
            label: 'Avg cost',
            width: 110,
            numeric: true,
            sortable: false,
            cell: (c, h) => AppMoneyText(h.avgCostLocal, currency: h.currency, style: c.text.bodyMedium),
          ),
          AppColumn(
            id: HoldingSort.price.name,
            label: 'Price',
            width: 110,
            numeric: true,
            cell: (c, h) => h.priceMissing
                ? AppTooltip(
                    message: 'No price yet — refresh to fetch',
                    child: AppIconView(AppIcon.warning, size: 18, color: c.app.warning),
                  )
                : AppMoneyText(h.priceLocal, currency: h.currency, style: c.text.bodyMedium),
          ),
          AppColumn(
            id: HoldingSort.dayPct.name,
            label: 'Day',
            width: 100,
            numeric: true,
            cell: (c, h) => AppChangeBadge(ratio: h.dayChangePct?.toDouble(), dense: true),
          ),
          AppColumn(
            id: HoldingSort.value.name,
            label: 'Value',
            width: 120,
            numeric: true,
            cell: (c, h) => AppMoneyText(h.marketValueBase, currency: base, style: c.text.titleSmall),
          ),
          AppColumn(
            id: HoldingSort.unrealized.name,
            label: 'Unrealized P&L',
            width: 150,
            numeric: true,
            cell: (c, h) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PnlText(amount: h.unrealizedBase, currency: base, showPercent: false, style: c.text.bodyMedium),
                Text(Fmt.percent(h.unrealizedPct), style: c.text.bodySmall!.copyWith(color: c.app.pnl(h.unrealizedBase.toDouble()))),
              ],
            ),
          ),
          AppColumn(
            id: HoldingSort.weight.name,
            label: 'Weight',
            width: 80,
            numeric: true,
            cell: (c, h) => Text(Fmt.percent(h.weight, signed: false, decimals: 1), style: c.text.bodyMedium),
          ),
        ];

        return AppTable<HoldingValuation>(
          columns: columns,
          rows: rows,
          sortColumnId: _sort.name,
          ascending: _asc,
          rowHeight: 62,
          emptyMessage: widget.emptyMessage,
          onSort: (id, asc) => setState(() {
            _sort = _sortFor(id);
            _asc = asc;
          }),
          onRowTap: widget.onTap,
          onRowSecondaryTap: _menu,
          rowSemanticLabel: (h) => '${h.symbol}, ${h.name}, value ${Fmt.currency(h.marketValueBase, base)}',
        );
      },
    );
  }
}

class _CompactList extends StatelessWidget {
  const _CompactList({required this.rows, required this.currency, required this.onTap, required this.onMenu, required this.emptyMessage});

  final List<HoldingValuation> rows;
  final String currency;
  final ValueChanged<HoldingValuation>? onTap;
  final Future<void> Function(HoldingValuation, Offset) onMenu;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.s6),
        child: Center(
          child: Text(emptyMessage, style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const AppDivider(),
          _CompactRow(
            h: rows[i],
            currency: currency,
            onTap: onTap == null ? null : () => onTap!(rows[i]),
            onLongPress: (p) => onMenu(rows[i], p),
          ),
        ],
      ],
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.h, required this.currency, this.onTap, required this.onLongPress});

  final HoldingValuation h;
  final String currency;
  final VoidCallback? onTap;
  final ValueChanged<Offset> onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${h.symbol}, ${h.name}, value ${Fmt.currency(h.marketValueBase, currency)}, day ${Fmt.percent(h.dayChangePct)}',
      child: AppTappable(
        onTap: onTap,
        onLongPress: () {
          final box = context.findRenderObject()! as RenderBox;
          onLongPress(box.localToGlobal(box.size.center(Offset.zero)));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s3),
          child: Row(
            children: [
              SymbolBadge(h.symbol),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.symbol, style: context.text.titleSmall),
                    Text(
                      '${Fmt.number(h.quantity, maxDecimals: 4)} × ${h.priceMissing ? '—' : Fmt.currency(h.priceLocal!, h.currency)}',
                      style: context.text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppMoneyText(h.marketValueBase, currency: currency, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  AppChangeBadge(ratio: h.dayChangePct?.toDouble(), dense: true, filled: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

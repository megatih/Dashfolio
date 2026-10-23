import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/portfolio.dart';
import '../dashboard/dashboard_widgets.dart';
import 'transaction_form.dart';

/// Filterable list of transactions with edit-on-tap and import-batch undo.
class TransactionsList extends ConsumerStatefulWidget {
  const TransactionsList({
    super.key,
    required this.transactions,
    this.portfolioNames = const {},
    this.symbolFilter,
    this.showFilters = true,
  });

  final List<PortfolioTransaction> transactions;
  final Map<int, String> portfolioNames;
  final String? symbolFilter;
  final bool showFilters;

  @override
  ConsumerState<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends ConsumerState<TransactionsList> {
  TxType? _type;
  String _query = '';

  Future<void> _undoBatch(String batchId, int count) async {
    final ok = await showAppConfirm(
      context,
      title: 'Undo import?',
      message: 'This deletes the $count transactions created by this import.',
      confirmLabel: 'Undo import',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final removed = await ref.read(portfolioRepositoryProvider).deleteImportBatch(batchId);
    if (mounted) showAppToast(context, 'Removed $removed imported transactions');
  }

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    var items = widget.transactions.where((t) => widget.symbolFilter == null || t.symbol == widget.symbolFilter).toList();
    final batches = <String, List<PortfolioTransaction>>{};
    for (final t in items) {
      if (t.importBatchId != null) batches.putIfAbsent(t.importBatchId!, () => []).add(t);
    }
    if (_type != null) items = items.where((t) => t.type == _type).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items
          .where((t) => (t.symbol ?? t.type.label).toLowerCase().contains(q) || (t.notes ?? '').toLowerCase().contains(q))
          .toList();
    }
    items.sort((a, b) {
      final c = b.tradeDate.compareTo(a.tradeDate);
      return c != 0 ? c : b.id.compareTo(a.id);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showFilters)
          Wrap(
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: AppTextField(
                  hint: 'Filter by symbol or note',
                  prefixIcon: AppIcon.filterList,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                width: 190,
                child: AppSelect<TxType?>(
                  value: _type,
                  options: [AppOption(null, 'All types'), for (final t in TxType.values) AppOption(t, t.label)],
                  onChanged: (t) => setState(() => _type = t),
                ),
              ),
            ],
          ),
        if (batches.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s3),
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            children: [
              for (final e in batches.entries)
                AppChip(
                  icon: AppIcon.undo,
                  label: 'Undo import ${Fmt.shortDate(e.value.first.createdAt)} (${e.value.length})',
                  onTap: () => _undoBatch(e.key, e.value.length),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.s3),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpace.s8),
            child: Center(
              child: Text('No transactions to show', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
            ),
          )
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const AppDivider(),
            TransactionTile(
              tx: items[i],
              portfolioName: widget.portfolioNames[items[i].portfolioId],
              onTap: () => showTransactionForm(context, editing: items[i]),
            ),
          ],
      ],
    );
  }
}

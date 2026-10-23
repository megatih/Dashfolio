import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/portfolio.dart';

/// A Luno-synced transaction: every field is read-only (it mirrors the exchange); only the note can be edited.
class SyncedTransactionSheet extends ConsumerStatefulWidget {
  const SyncedTransactionSheet({super.key, required this.tx});

  final PortfolioTransaction tx;

  @override
  ConsumerState<SyncedTransactionSheet> createState() => _SyncedTransactionSheetState();
}

class _SyncedTransactionSheetState extends ConsumerState<SyncedTransactionSheet> {
  late final _notes = TextEditingController(text: widget.tx.notes ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final text = _notes.text.trim();
    await ref.read(portfolioRepositoryProvider).updateTransaction(widget.tx.copyWith(notes: text, clearNotes: text.isEmpty));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tx;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: context.text.bodySmall)),
          Expanded(child: Text(value, style: context.text.bodyMedium)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('${t.type.label}${t.symbol == null ? '' : ' · ${t.symbol}'}', style: context.text.titleLarge),
                ),
              ),
              AppIconButton(icon: AppIcon.close, tooltip: 'Close', size: 40, onPressed: () => Navigator.of(context).pop(false)),
            ],
          ),
          const SizedBox(height: AppSpace.s2),
          Row(
            children: [
              AppIconView(AppIcon.lock, size: 16, color: context.app.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Synced from Luno. Changes are made in Luno; only the note can be edited here.', style: context.text.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          row(
            'Date',
            t.executedAt == null ? Fmt.date(t.tradeDate) : '${Fmt.date(t.executedAt!.toLocal())}, ${Fmt.time(t.executedAt!.toLocal())}',
          ),
          if (t.symbol != null) row('Quantity', Fmt.number(t.quantity, maxDecimals: 8)),
          row(t.symbol == null ? 'Amount' : 'Price', Fmt.currency(t.price, t.currency)),
          if (t.fees > Decimal.zero)
            row(
              'Fees',
              t.symbol != null && (t.type.name == 'transferOut' || t.type.name == 'fee')
                  ? Fmt.number(t.fees, maxDecimals: 8)
                  : Fmt.currency(t.fees, t.currency),
            ),
          row('Currency', t.currency),
          if (t.externalId != null) row('Reference', t.externalId!),
          const SizedBox(height: AppSpace.s4),
          AppTextField(controller: _notes, label: 'Note', maxLines: 3, maxLength: 500),
          const SizedBox(height: AppSpace.s4),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(label: 'Save note', kind: AppButtonKind.primary, loading: _saving, onPressed: _saving ? null : _save),
          ),
        ],
      ),
    );
  }
}

/// Tells the user why a synced portfolio cannot be edited by hand.
void explainSyncedPortfolio(BuildContext context) =>
    showAppToast(context, 'This portfolio mirrors your Luno account, so transactions are added in Luno and synced here.');

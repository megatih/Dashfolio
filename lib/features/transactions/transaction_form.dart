import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../core/clock.dart';
import '../../core/decimal_ext.dart';
import '../../core/format.dart';
import '../../core/result.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/services/fx.dart';
import '../../domain/services/holdings_engine.dart';
import '../../domain/services/transaction_validation.dart';
import '../common/small_widgets.dart';
import '../luno/synced_transaction_sheet.dart';
import '../common/symbol_search.dart';

/// Opens the add/edit transaction sheet. Returns true when something was saved.
///
/// Luno-synced data is read-only: tapping a synced transaction opens a sheet where only the note can be edited, and a
/// synced portfolio is never offered as the target of a new transaction.
Future<bool?> showTransactionForm(BuildContext context, {int? portfolioId, PortfolioTransaction? editing, String? symbol, TxType? type}) {
  if (editing != null && editing.isSynced) {
    return showAppSheet<bool>(context, builder: (_) => SyncedTransactionSheet(tx: editing));
  }
  final synced = ProviderScope.containerOf(context).read(lunoConnectionByPortfolioProvider);
  if (portfolioId != null && synced.containsKey(portfolioId)) {
    explainSyncedPortfolio(context);
    if (editing == null && synced.length >= ProviderScope.containerOf(context).read(activePortfoliosProvider).length) return Future.value();
    portfolioId = null; // let the user pick one of their own portfolios instead
  }
  return showAppSheet<bool>(
    context,
    builder: (_) => TransactionForm(portfolioId: portfolioId, editing: editing, initialSymbol: symbol, initialType: type),
  );
}

Decimal? parseDecimal(String s) {
  final t = s.trim().replaceAll(',', '');
  if (t.isEmpty) return null;
  return Decimal.tryParse(t);
}

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.portfolioId, this.editing, this.initialSymbol, this.initialType});

  final int? portfolioId;
  final PortfolioTransaction? editing;
  final String? initialSymbol;
  final TxType? initialType;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late int? _portfolioId = widget.editing?.portfolioId ?? widget.portfolioId;
  late TxType _type = widget.editing?.type ?? widget.initialType ?? TxType.buy;
  String? _symbol;
  String? _symbolName;
  String _currency = 'USD';
  late DateTime _date = widget.editing?.tradeDate ?? dateOnly(ref.read(clockProvider).now());

  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _fees = TextEditingController();
  final _fx = TextEditingController();
  final _notes = TextEditingController();

  bool _priceTouched = false, _fxTouched = false;
  bool _saving = false;
  Map<String, String> _errors = const {};
  int _loadSeq = 0;

  String get _base => ref.read(appSettingsProvider).baseCurrency;
  bool get _isEdit => widget.editing != null;
  bool get _cashOnly => !_type.hasSymbol;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _symbol = e.symbol;
      _currency = e.currency;
      _qty.text = e.type.hasSymbol ? e.quantity.toString() : '';
      _price.text = e.price.toString();
      _fees.text = e.fees == Decimal.zero ? '' : e.fees.toString();
      _fx.text = e.fxRateToBase.toString();
      _notes.text = e.notes ?? '';
      _priceTouched = _fxTouched = true;
      final name = ref.read(instrumentsProvider).value?[e.symbol]?.name ?? ref.read(quotesProvider).value?[e.symbol]?.name;
      _symbolName = name;
    } else {
      _fx.text = '1';
      _portfolioId ??= ref
          .read(activePortfoliosProvider)
          .where((p) => !ref.read(lunoConnectionByPortfolioProvider).containsKey(p.id))
          .firstOrNull
          ?.id;
      final s = widget.initialSymbol;
      if (s != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _setSymbol(s, ref.read(quotesProvider).value?[s]?.name));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_qty, _price, _fees, _fx, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- data loading ----------------------------------------------------------

  Future<void> _setSymbol(String symbol, String? name) async {
    final seq = ++_loadSeq;
    final repo = ref.read(marketDataRepositoryProvider);
    setState(() {
      _symbol = symbol;
      _symbolName = name;
      _errors = {..._errors}..remove('symbol');
    });
    // Make sure we know the instrument currency (needed for FX and valuation).
    var quote = ref.read(quotesProvider).value?[symbol];
    if (quote == null) {
      await repo.refreshQuotes([symbol]);
      quote = (await repo.quotesSnapshot())[symbol];
    }
    if (!mounted || seq != _loadSeq) return;
    setState(() {
      _currency = quote?.currency ?? 'USD';
      _symbolName = quote?.name ?? _symbolName;
    });
    await _loadFx();
    await _prefill();
  }

  Future<void> _loadFx() async {
    if (_fxTouched && _isEdit) return;
    final base = _base;
    if (_currency == base) {
      if (!_fxTouched) _fx.text = '1';
      return;
    }
    final repo = ref.read(marketDataRepositoryProvider);
    Decimal? rate;
    final r = await repo.dailyHistory(fxSymbol(_currency, base), _date.subtract(const Duration(days: 10)));
    if (r case Ok(:final value)) {
      final c = value.candles.where((c) => !c.time.isAfter(_date)).lastOrNull ?? value.candles.firstOrNull;
      if (c != null) rate = dec(c.close);
    }
    rate ??= ref.read(fxRatesProvider).rate(_currency, base);
    if (!mounted || _fxTouched) return;
    setState(() => _fx.text = rate?.toString() ?? '');
  }

  /// Prefills the price with the close on the trade date (buy/sell/opening) or the held quantity (dividend).
  Future<void> _prefill() async {
    final symbol = _symbol;
    if (symbol == null) return;
    if (_type == TxType.dividend && _qty.text.isEmpty && _portfolioId != null) {
      final txs = ref.read(transactionsByPortfolioProvider)[_portfolioId] ?? const [];
      final held = const HoldingsEngine().quantityAt(txs, symbol, _date);
      if (held > Decimal.zero) _qty.text = held.toString();
    }
    if (_priceTouched || !const {TxType.buy, TxType.sell, TxType.openingPosition}.contains(_type)) return;
    final repo = ref.read(marketDataRepositoryProvider);
    final r = await repo.dailyHistory(symbol, _date.subtract(const Duration(days: 10)));
    if (!mounted || _priceTouched) return;
    if (r case Ok(:final value)) {
      final c = value.candles.where((c) => !c.time.isAfter(_date)).lastOrNull;
      if (c != null) setState(() => _price.text = dec(c.close).toString());
    }
  }

  // ---- actions ---------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context,
      initial: _date,
      first: DateTime(1970),
      last: ref.read(clockProvider).now(),
      helpText: 'Trade date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime.utc(picked.year, picked.month, picked.day);
      _errors = {..._errors}..remove('date');
    });
    await _loadFx();
    await _prefill();
  }

  TxDraft _draft() => TxDraft(
    type: _type,
    symbol: _symbol,
    date: _date,
    quantity: _cashOnly ? Decimal.one : parseDecimal(_qty.text),
    price: parseDecimal(_price.text),
    fees: parseDecimal(_fees.text) ?? Decimal.zero,
    fxRate: _cashOnly ? Decimal.one : parseDecimal(_fx.text),
  );

  Future<void> _save() async {
    final pid = _portfolioId;
    if (pid == null) {
      showAppToast(context, 'Create a portfolio first', error: true);
      return;
    }
    final portfolio =
        ref.read(activePortfoliosProvider).where((p) => p.id == pid).firstOrNull ??
        ref.read(portfoliosProvider).value?.where((p) => p.id == pid).firstOrNull;
    final existing = ref.read(transactionsByPortfolioProvider)[pid] ?? const <PortfolioTransaction>[];
    final draft = _draft();
    final v = const TransactionValidator().validate(
      draft,
      existing: existing,
      excludeId: widget.editing?.id,
      now: ref.read(clockProvider).now(),
      method: portfolio?.costMethod ?? CostMethod.average,
    );
    if (!v.isValid) {
      setState(() => _errors = v.errors);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(portfolioRepositoryProvider);
    final base = _base;
    final tx = PortfolioTransaction(
      id: widget.editing?.id ?? 0,
      portfolioId: pid,
      symbol: _cashOnly ? null : _symbol,
      type: _type,
      tradeDate: _date,
      quantity: draft.quantity!,
      price: draft.price!,
      fees: draft.fees ?? Decimal.zero,
      currency: _cashOnly ? base : _currency,
      fxRateToBase: draft.fxRate!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      importBatchId: widget.editing?.importBatchId,
      createdAt: widget.editing?.createdAt ?? ref.read(clockProvider).now(),
      source: widget.editing?.source ?? TxSource.manual,
      connectionId: widget.editing?.connectionId,
      externalId: widget.editing?.externalId,
      executedAt: widget.editing?.executedAt,
    );
    try {
      if (_isEdit) {
        await repo.updateTransaction(tx);
      } else {
        await repo.addTransaction(tx);
      }
      if (tx.symbol != null) {
        final q = ref.read(quotesProvider).value?[tx.symbol];
        await repo.upsertInstrument(
          Instrument(
            symbol: tx.symbol!,
            name: _symbolName ?? q?.name ?? tx.symbol!,
            quoteType: q?.quoteType,
            exchange: q?.exchange,
            currency: tx.currency,
            sector: q?.sector,
            industry: q?.industry,
          ),
        );
        // Fetch prices for the new holding (and its FX pair) so the dashboard values it right away.
        final syms = {tx.symbol!, if (tx.currency != base) fxSymbol(tx.currency, base)};
        ref.read(marketDataRepositoryProvider).refreshQuotes(syms);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAppToast(context, 'Could not save: $e', error: true);
      }
    }
  }

  Future<void> _delete() async {
    final e = widget.editing!;
    final all = ref.read(transactionsByPortfolioProvider)[e.portfolioId] ?? const <PortfolioTransaction>[];
    final method = ref.read(activePortfoliosProvider).where((p) => p.id == e.portfolioId).firstOrNull?.costMethod ?? CostMethod.average;
    final breaks = const TransactionValidator().deleteBreaksHistory(e, all, method);
    final ok = await showAppConfirm(
      context,
      title: 'Delete transaction?',
      message: breaks
          ? 'Later sells depend on these shares; deleting this will leave them without enough shares and hide part of the position.'
          : 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(portfolioRepositoryProvider).deleteTransaction(e.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  // ---- UI --------------------------------------------------------------------

  String get _qtyLabel => switch (_type) {
    TxType.dividend => 'Shares',
    TxType.split => 'New shares (e.g. 4)',
    _ => 'Quantity',
  };

  String get _priceLabel => switch (_type) {
    TxType.openingPosition => 'Average cost per share ($_currency)',
    TxType.dividend => 'Dividend per share ($_currency)',
    TxType.split => 'Old shares (e.g. 1)',
    TxType.deposit || TxType.withdrawal || TxType.fee => 'Amount ($_base)',
    _ => 'Price per share ($_currency)',
  };

  @override
  Widget build(BuildContext context) {
    final synced = ref.watch(lunoConnectionByPortfolioProvider);
    final portfolios = ref.watch(activePortfoliosProvider).where((p) => !synced.containsKey(p.id)).toList();
    final base = ref.watch(appSettingsProvider.select((s) => s.baseCurrency));
    final needsFx = !_cashOnly && _currency != base;
    final numFormatter = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    const numKeyboard = TextInputType.numberWithOptions(decimal: true);

    final total = _totalAmount();

    return AppSheetScaffold(
      title: _isEdit ? 'Edit transaction' : 'Add transaction',
      confirmLabel: _isEdit ? 'Save changes' : 'Add transaction',
      shortConfirmLabel: _isEdit ? 'Save' : 'Add',
      onConfirm: _save,
      busy: _saving,
      closeResult: false,
      actionsGap: AppSpace.s5,
      destructiveLabel: _isEdit ? 'Delete' : null,
      onDestructive: _delete,
      footer: _errors.isNotEmpty ? 'Please fix the highlighted fields.' : null,
      children: [
        AppSection(
          bare: true,
          children: [
            if (portfolios.length > 1 || _portfolioId == null)
              AppSelect<int>(
                label: 'Portfolio',
                value: portfolios.any((p) => p.id == _portfolioId) ? _portfolioId : null,
                hint: 'Choose a portfolio',
                options: [for (final p in portfolios) AppOption(p.id, p.name)],
                onChanged: _isEdit ? null : (v) => setState(() => _portfolioId = v),
              ),
            AppSelect<TxType>(
              label: 'Type',
              value: _type,
              options: [
                for (final t in TxType.values) AppOption(t, t == TxType.openingPosition ? 'Opening position (qty + avg cost)' : t.label),
              ],
              onChanged: (t) {
                if (t == null) return;
                setState(() {
                  _type = t;
                  _errors = const {};
                });
                _prefill();
              },
            ),
            if (!_cashOnly)
              _symbol == null
                  ? SymbolSearchField(
                      label: 'Symbol',
                      autofocus: !_isEdit,
                      errorText: _errors['symbol'],
                      onSelected: (r) => _setSymbol(r.symbol, r.name),
                    )
                  : _SymbolChip(
                      symbol: _symbol!,
                      name: _symbolName,
                      currency: _currency,
                      onChange: _isEdit ? null : () => setState(() => _symbol = null),
                    ),
            _DateField(date: _date, error: _errors['date'], onTap: _pickDate),
          ],
        ),
        AppSection(
          bare: true,
          children: [
            if (!_cashOnly)
              AppTextField(
                controller: _qty,
                label: _qtyLabel,
                hint: '0',
                keyboardType: numKeyboard,
                inputFormatters: numFormatter,
                errorText: _errors['quantity'],
                onChanged: (_) => setState(() => _errors = {..._errors}..remove('quantity')),
              ),
            AppTextField(
              controller: _price,
              label: _priceLabel,
              hint: '0.00',
              keyboardType: numKeyboard,
              inputFormatters: numFormatter,
              errorText: _errors['price'],
              onChanged: (_) {
                _priceTouched = true;
                setState(() => _errors = {..._errors}..remove('price'));
              },
            ),
            if (const {TxType.buy, TxType.sell, TxType.dividend}.contains(_type))
              AppTextField(
                controller: _fees,
                label: _type == TxType.dividend ? 'Withholding / fees ($_currency, optional)' : 'Fees ($_currency, optional)',
                hint: '0.00',
                keyboardType: numKeyboard,
                inputFormatters: numFormatter,
                errorText: _errors['fees'],
              ),
            if (needsFx)
              AppTextField(
                controller: _fx,
                label: 'Exchange rate ($_currency → $base)',
                hint: 'e.g. 1.0850',
                keyboardType: numKeyboard,
                inputFormatters: numFormatter,
                errorText: _errors['fx'],
                onChanged: (_) {
                  _fxTouched = true;
                  setState(() => _errors = {..._errors}..remove('fx'));
                },
              ),
          ],
        ),
        AppSection(
          bare: true,
          children: [AppTextField(controller: _notes, label: 'Notes (optional)', maxLines: 2)],
        ),
        if (total == null)
          const AppGap(0)
        else
          AppSection(
            bare: true,
            children: [_TotalRow(total: total, currency: _cashOnly ? base : _currency)],
          ),
      ],
    );
  }

  /// The computed total of the entered values, or null when there is nothing to show.
  Decimal? _totalAmount() {
    final d = _draft();
    if (const {TxType.split}.contains(_type) || d.quantity == null || d.price == null) return null;
    var total = d.quantity! * d.price!;
    final fees = d.fees ?? Decimal.zero;
    total = _type == TxType.sell ? total - fees : total + (_type == TxType.buy ? fees : Decimal.zero);
    return total == Decimal.zero ? null : total;
  }
}

class _SymbolChip extends StatelessWidget {
  const _SymbolChip({required this.symbol, required this.name, required this.currency, this.onChange});

  final String symbol;
  final String? name;
  final String currency;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    return AppField(
      label: 'Symbol',
      child: AppSurface(
        shape: AppShape.inset,
        depth: 2,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3, vertical: AppSpace.s2),
        child: Row(
          children: [
            SymbolBadge(symbol, size: 36),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$symbol · $currency', style: context.text.titleSmall),
                  if (name != null) Text(name!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onChange != null) AppIconButton(icon: AppIcon.swapHorizontal, tooltip: 'Change symbol', size: 40, onPressed: onChange),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap, this.error});

  final DateTime date;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    return AppField(
      label: 'Date',
      errorText: error,
      child: AppPressable(
        onTap: onTap,
        semanticLabel: 'Trade date ${Fmt.date(date)}',
        builder: (context, s) => AppSurface(
          shape: AppShape.inset,
          depth: 2,
          border: Border.all(color: error != null ? n.loss : Colors.transparent, width: 1.5),
          constraints: const BoxConstraints(minHeight: AppSpace.minHit),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s3),
          child: Row(
            children: [
              AppIconView(AppIcon.event, size: 18, color: n.textMuted),
              const SizedBox(width: AppSpace.s2),
              Expanded(child: Text(Fmt.date(date), style: context.text.bodyLarge)),
              AppIconView(AppIcon.expandMore, color: n.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the computed total of the entered values.
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.total, required this.currency});

  final Decimal total;
  final String currency;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Total', style: context.text.bodyMedium),
      AppMoneyText(total, currency: currency, style: context.text.titleSmall),
    ],
  );
}

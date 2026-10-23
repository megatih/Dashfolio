import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/file_service.dart';
import '../../app/portfolio_providers.dart';
import '../../app/providers.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/services/csv_import.dart';
import '../../routing/routes.dart';
import '../common/page_scaffold.dart';
import 'import_committer.dart';

enum _Step { file, columns, preview, done }

/// CSV import wizard: pick file → map columns → preview/validate → commit as one undoable batch.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.initialPortfolioId});

  final int? initialPortfolioId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  static const _importer = CsvImporter();

  _Step _step = _Step.file;
  int? _portfolioId;
  String? _fileName;
  List<List<String>> _rows = const [];
  ColumnMapping _mapping = const ColumnMapping();
  ImportOptions _options = const ImportOptions();
  List<ImportRow> _parsed = const [];
  bool _skipDuplicates = true;
  bool _busy = false;
  String? _error;
  ImportResult? _result;
  final _presetName = TextEditingController();
  final _defaultCurrency = TextEditingController();

  @override
  void initState() {
    super.initState();
    _portfolioId =
        widget.initialPortfolioId ??
        _importable(ref.read(activePortfoliosProvider), ref.read(lunoConnectionByPortfolioProvider)).firstOrNull?.id;
  }

  @override
  void dispose() {
    _presetName.dispose();
    _defaultCurrency.dispose();
    super.dispose();
  }

  List<String> get _headers => _rows.isEmpty ? const [] : _rows.first;

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = await ref.read(fileServiceProvider).pickText(const ['csv', 'txt', 'tsv']);
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }
      final rows = parseCsvText(picked.text);
      if (rows.length < 2) {
        setState(() {
          _busy = false;
          _error = 'That file has no data rows. Check that it is a CSV export with a header row.';
        });
        return;
      }
      setState(() {
        _busy = false;
        _fileName = picked.name;
        _rows = rows;
        _mapping = _importer.autoDetect(rows.first);
        _step = _Step.columns;
      });
    } on Object catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not read the file: $e';
      });
    }
  }

  void _toPreview() {
    final needsType = _mapping.type == null && _options.defaultType == null;
    if (_mapping.date == null || needsType) {
      setState(
        () => _error =
            'Map the ${[if (_mapping.date == null) 'date', if (needsType) 'type'].join(' and ')} column${needsType && _mapping.date == null ? 's' : ''} (or choose a default type).',
      );
      return;
    }
    final options = ImportOptions(
      dateOrder: _options.dateOrder,
      decimalMark: _options.decimalMark,
      defaultType: _options.defaultType,
      defaultCurrency: _defaultCurrency.text.trim().isEmpty ? null : _defaultCurrency.text.trim().toUpperCase(),
    );
    final now = ref.read(clockProvider).now();
    var parsed = _importer.parse(rows: _rows, mapping: _mapping, options: options, today: now);
    final existing = ref.read(transactionsByPortfolioProvider)[_portfolioId] ?? const <PortfolioTransaction>[];
    parsed = _importer.markDuplicates(parsed, existing);
    setState(() {
      _options = options;
      _parsed = parsed;
      _error = null;
      _step = _Step.preview;
    });
  }

  List<ImportRow> get _toImport => [
    for (final r in _parsed)
      if (r.valid && !(r.duplicate && _skipDuplicates)) r,
  ];

  Future<void> _commit() async {
    final pid = _portfolioId;
    if (pid == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final committer = ImportCommitter(
        portfolios: ref.read(portfolioRepositoryProvider),
        market: ref.read(marketDataRepositoryProvider),
        clock: ref.read(clockProvider),
      );
      final result = await committer.commit(
        portfolioId: pid,
        rows: _toImport,
        baseCurrency: ref.read(appSettingsProvider).baseCurrency,
        knownQuotes: ref.read(quotesProvider).value ?? const {},
        currentFx: ref.read(fxRatesProvider),
        defaultCurrency: _options.defaultCurrency,
      );
      setState(() {
        _busy = false;
        _result = result;
        _step = _Step.done;
      });
    } on Object catch (e) {
      setState(() {
        _busy = false;
        _error = 'Import failed: $e';
      });
    }
  }

  Future<void> _savePreset() async {
    final name = _presetName.text.trim();
    if (name.isEmpty) return;
    await ref.read(portfolioRepositoryProvider).saveImportMapping(name, {
      'columns': _mapping.toJson(),
      'dateOrder': _options.dateOrder.name,
      'decimalMark': _options.decimalMark.name,
      'defaultType': _options.defaultType?.dbName,
    });
    if (mounted) {
      _presetName.clear();
      showAppToast(context, 'Saved mapping "$name"');
    }
  }

  void _applyPreset(ImportMapping preset) {
    final cols = ColumnMapping.fromJson((preset.mapping['columns'] as Map).cast<String, Object?>());
    // Only keep mapped headers that exist in this file.
    var m = const ColumnMapping();
    for (final f in ColumnMapping.fields) {
      final h = cols[f];
      if (h != null && _headers.contains(h)) m = m.with_(f, h);
    }
    setState(() {
      _mapping = m;
      _options = ImportOptions(
        dateOrder: DateOrder.values.firstWhere((d) => d.name == preset.mapping['dateOrder'], orElse: () => DateOrder.auto),
        decimalMark: DecimalMark.values.firstWhere((d) => d.name == preset.mapping['decimalMark'], orElse: () => DecimalMark.dot),
        defaultType: TxType.values.where((t) => t.dbName == preset.mapping['defaultType']).firstOrNull,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Luno-synced portfolios mirror an exchange account and cannot receive imported rows.
    final portfolios = _importable(ref.watch(activePortfoliosProvider), ref.watch(lunoConnectionByPortfolioProvider));
    final leading = Padding(
      padding: const EdgeInsets.only(right: AppSpace.s3),
      child: AppIconButton(
        icon: AppIcon.arrowBack,
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.settings),
      ),
    );

    final Widget content;
    if (portfolios.isEmpty) {
      content = const AppCard(
        child: AppEmptyState(
          icon: AppIcon.folderOpen,
          title: 'Create a portfolio first',
          message: 'Imported transactions need a portfolio to live in.',
          compact: true,
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepIndicator(step: _step.index),
          const SizedBox(height: AppSpace.s5),
          if (_error != null) ...[
            Semantics(
              liveRegion: true,
              child: AppSurface(
                shape: AppShape.inset,
                depth: 1,
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Row(
                  children: [
                    AppIconView(AppIcon.error, color: context.app.loss),
                    const SizedBox(width: AppSpace.s3),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s4),
          ],
          switch (_step) {
            _Step.file => _fileStep(portfolios),
            _Step.columns => _columnsStep(),
            _Step.preview => _previewStep(),
            _Step.done => _doneStep(),
          },
        ],
      );
    }
    return PageScaffold(title: 'Import transactions', leading: leading, showRefresh: false, child: content);
  }

  Widget _fileStep(List<Portfolio> portfolios) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('1. Choose a file'),
        const SizedBox(height: AppSpace.s2),
        Text(
          'Export your transactions from your broker as CSV. Dashfolio detects common column names and lets you adjust them next.',
          style: context.text.bodyMedium,
        ),
        const SizedBox(height: AppSpace.s5),
        AppSelect<int>(
          label: 'Import into portfolio',
          value: portfolios.any((p) => p.id == _portfolioId) ? _portfolioId : null,
          options: [for (final p in portfolios) AppOption(p.id, p.name)],
          onChanged: (v) => setState(() => _portfolioId = v),
        ),
        const SizedBox(height: AppSpace.s5),
        AppButton(
          label: 'Choose CSV file…',
          icon: AppIcon.uploadFile,
          kind: AppButtonKind.primary,
          loading: _busy,
          onPressed: _portfolioId == null ? null : _pick,
        ),
      ],
    ),
  );

  Widget _mapDropdown(String field, String label, {bool required = false}) {
    final value = _mapping[field];
    return SizedBox(
      width: 260,
      child: AppSelect<String?>(
        label: required ? '$label *' : label,
        value: _headers.contains(value) ? value : null,
        options: [AppOption(null, '— not mapped —'), for (final h in _headers) AppOption(h, h)],
        onChanged: (h) => setState(() => _mapping = _mapping.with_(field, h)),
      ),
    );
  }

  Widget _columnsStep() {
    final presets = ref.watch(importMappingsProvider).value ?? const <ImportMapping>[];
    final sample = _rows.skip(1).take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle('2. Match columns', trailing: Text('${_rows.length - 1} rows · $_fileName', style: context.text.bodySmall)),
              const SizedBox(height: AppSpace.s4),
              if (presets.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Saved mappings:', style: context.text.labelMedium),
                    for (final p in presets) AppChip(label: p.name, icon: AppIcon.bookmark, onTap: () => _applyPreset(p)),
                  ],
                ),
                const SizedBox(height: AppSpace.s4),
              ],
              Wrap(
                spacing: AppSpace.s4,
                runSpacing: AppSpace.s4,
                children: [
                  _mapDropdown('date', 'Date', required: true),
                  _mapDropdown('type', 'Type / action'),
                  _mapDropdown('symbol', 'Symbol'),
                  _mapDropdown('quantity', 'Quantity'),
                  _mapDropdown('price', 'Price'),
                  _mapDropdown('amount', 'Total amount'),
                  _mapDropdown('fees', 'Fees'),
                  _mapDropdown('currency', 'Currency'),
                  _mapDropdown('notes', 'Notes'),
                ],
              ),
              const SizedBox(height: AppSpace.s5),
              Text('Format', style: context.text.titleSmall),
              const SizedBox(height: AppSpace.s3),
              Wrap(
                spacing: AppSpace.s4,
                runSpacing: AppSpace.s4,
                children: [
                  SizedBox(
                    width: 300,
                    child: AppSelect<DateOrder>(
                      label: 'Date format',
                      value: _options.dateOrder,
                      options: [for (final d in DateOrder.values) AppOption(d, d.label)],
                      onChanged: (v) => setState(
                        () => _options = ImportOptions(dateOrder: v!, decimalMark: _options.decimalMark, defaultType: _options.defaultType),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: AppSelect<DecimalMark>(
                      label: 'Number format',
                      value: _options.decimalMark,
                      options: [for (final d in DecimalMark.values) AppOption(d, d.label)],
                      onChanged: (v) => setState(
                        () => _options = ImportOptions(dateOrder: _options.dateOrder, decimalMark: v!, defaultType: _options.defaultType),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: AppSelect<TxType?>(
                      label: 'Default type (when blank)',
                      value: _options.defaultType,
                      options: [AppOption(null, 'None'), for (final t in TxType.values) AppOption(t, t.label)],
                      onChanged: (v) => setState(
                        () => _options = ImportOptions(dateOrder: _options.dateOrder, decimalMark: _options.decimalMark, defaultType: v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: AppTextField(
                      controller: _defaultCurrency,
                      label: 'Default currency',
                      hint: 'auto',
                      maxLength: 3,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                        TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
                      ],
                    ),
                  ),
                ],
              ),
              if (sample.isNotEmpty) ...[
                const SizedBox(height: AppSpace.s5),
                Text('First rows of your file', style: context.text.titleSmall),
                const SizedBox(height: AppSpace.s2),
                AppSimpleTable(headers: _headers, rows: sample, headerStyle: context.text.labelMedium, cellStyle: context.text.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s5),
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(label: 'Back', onPressed: () => setState(() => _step = _Step.file)),
            AppButton(label: 'Preview', kind: AppButtonKind.primary, icon: AppIcon.visibility, onPressed: _toPreview),
            SizedBox(
              width: 200,
              child: AppTextField(controller: _presetName, hint: 'Save mapping as…'),
            ),
            AppButton(label: 'Save mapping', icon: AppIcon.bookmarkAdd, compact: true, onPressed: _savePreset),
          ],
        ),
      ],
    );
  }

  Widget _previewStep() {
    final n = context.app;
    final valid = _parsed.where((r) => r.valid && !r.duplicate).length;
    final dup = _parsed.where((r) => r.valid && r.duplicate).length;
    final bad = _parsed.where((r) => !r.valid).length;
    final importing = _toImport.length;
    final shown = _parsed.take(300).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('3. Review'),
              const SizedBox(height: AppSpace.s3),
              Wrap(
                spacing: AppSpace.s3,
                runSpacing: AppSpace.s2,
                children: [
                  _Pill(label: '$valid ready', color: n.gain, icon: AppIcon.checkCircle),
                  if (dup > 0) _Pill(label: '$dup already imported', color: n.warning, icon: AppIcon.contentCopy),
                  if (bad > 0) _Pill(label: '$bad with errors', color: n.loss, icon: AppIcon.error),
                ],
              ),
              if (dup > 0) ...[
                const SizedBox(height: AppSpace.s3),
                Row(
                  children: [
                    AppSwitch(
                      value: _skipDuplicates,
                      onChanged: (v) => setState(() => _skipDuplicates = v),
                      semanticLabel: 'Skip rows that already exist',
                    ),
                    const SizedBox(width: AppSpace.s2),
                    Expanded(child: Text('Skip rows that already exist in this portfolio', style: context.text.bodyMedium)),
                  ],
                ),
              ],
              if (bad > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s2),
                  child: Text(
                    'Rows with errors are skipped. Fix the file or the column mapping to include them.',
                    style: context.text.bodySmall,
                  ),
                ),
              const SizedBox(height: AppSpace.s4),
              AppTable<ImportRow>(
                rowHeight: 48,
                columns: [
                  AppColumn(
                    id: 'line',
                    label: 'Line',
                    width: 64,
                    sortable: false,
                    cell: (c, r) => Text('${r.line}', style: c.text.bodySmall),
                  ),
                  AppColumn(
                    id: 'status',
                    label: 'Status',
                    width: 220,
                    flex: 2,
                    sortable: false,
                    cell: (c, r) => r.valid
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIconView(
                                r.duplicate ? AppIcon.contentCopy : AppIcon.checkCircle,
                                size: 16,
                                color: r.duplicate ? n.warning : n.gain,
                              ),
                              const SizedBox(width: 6),
                              Text(r.duplicate ? 'Duplicate' : 'Ready', style: c.text.bodySmall),
                            ],
                          )
                        : AppTooltip(
                            message: r.errors.join('\n'),
                            child: Text(
                              r.errors.first,
                              style: c.text.bodySmall!.copyWith(color: n.loss),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                  AppColumn(
                    id: 'date',
                    label: 'Date',
                    width: 110,
                    sortable: false,
                    cell: (c, r) => Text(r.date == null ? '—' : Fmt.isoDate(r.date!), style: c.text.bodySmall),
                  ),
                  AppColumn(
                    id: 'type',
                    label: 'Type',
                    width: 110,
                    sortable: false,
                    cell: (c, r) => Text(r.type?.label ?? '—', style: c.text.bodySmall),
                  ),
                  AppColumn(
                    id: 'symbol',
                    label: 'Symbol',
                    width: 100,
                    sortable: false,
                    cell: (c, r) => Text(r.symbol ?? '—', style: c.text.titleSmall),
                  ),
                  AppColumn(
                    id: 'qty',
                    label: 'Qty',
                    width: 100,
                    numeric: true,
                    sortable: false,
                    cell: (c, r) => Text(r.quantity == null ? '—' : Fmt.number(r.quantity!, maxDecimals: 6), style: c.text.bodySmall),
                  ),
                  AppColumn(
                    id: 'price',
                    label: 'Price',
                    width: 100,
                    numeric: true,
                    sortable: false,
                    cell: (c, r) => Text(r.price == null ? '—' : Fmt.number(r.price!, maxDecimals: 6), style: c.text.bodySmall),
                  ),
                ],
                rows: shown,
              ),
              if (_parsed.length > shown.length)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.s3),
                  child: Text('Showing the first ${shown.length} of ${_parsed.length} rows.', style: context.text.bodySmall),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s5),
        Wrap(
          spacing: AppSpace.s3,
          runSpacing: AppSpace.s3,
          children: [
            AppButton(label: 'Back', onPressed: () => setState(() => _step = _Step.columns)),
            AppButton(
              label: importing == 0 ? 'Nothing to import' : 'Import $importing transactions',
              kind: AppButtonKind.primary,
              icon: AppIcon.downloadDone,
              loading: _busy,
              onPressed: importing == 0 ? null : _commit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _doneStep() {
    final r = _result!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEmptyState(
            icon: AppIcon.checkCircle,
            title: 'Imported ${r.imported} transactions',
            message: 'Prices for the new holdings are loading in the background.',
            compact: true,
          ),
          if (r.fxFallbacks > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s3),
              child: Text(
                '${r.fxFallbacks} rows used today\'s exchange rate because no historical rate was available. You can edit the rate on each transaction.',
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          if (r.currencyFallbacks > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.s2),
              child: Text(
                '${r.currencyFallbacks} rows had an unknown currency and used your default.',
                style: context.text.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSpace.s5),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s3,
            children: [
              AppButton(
                label: 'Undo import',
                icon: AppIcon.undo,
                onPressed: () async {
                  final ok = await showAppConfirm(
                    context,
                    title: 'Undo import?',
                    message: 'This deletes the ${r.imported} transactions created by this import.',
                    confirmLabel: 'Undo import',
                    destructive: true,
                  );
                  if (!ok || !mounted) return;
                  await ref.read(portfolioRepositoryProvider).deleteImportBatch(r.batchId);
                  if (mounted) context.go(Routes.portfolios);
                },
              ),
              AppButton(label: 'View portfolio', kind: AppButtonKind.primary, onPressed: () => context.go(Routes.portfolio(_portfolioId!))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['File', 'Columns', 'Review', 'Done'];
    final n = context.app;
    return Semantics(
      label: 'Step ${step + 1} of 4: ${labels[step]}',
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= step ? n.accent : Colors.transparent,
                border: Border.all(color: i <= step ? n.accent : n.outline),
              ),
              child: i < step
                  ? AppIconView(AppIcon.check, size: 16, color: n.onAccent)
                  : Text('${i + 1}', style: context.text.labelMedium!.copyWith(color: i <= step ? n.onAccent : n.textMuted)),
            ),
            const SizedBox(width: 6),
            Text(labels[i], style: context.text.labelMedium!.copyWith(color: i == step ? n.text : n.textMuted)),
            if (i < labels.length - 1)
              Expanded(
                child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 8), color: n.outline),
              ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final AppIcon icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconView(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: context.text.labelMedium!.copyWith(color: color)),
      ],
    ),
  );
}

List<Portfolio> _importable(List<Portfolio> all, Map<int, LunoConnection> synced) => [
  for (final p in all)
    if (!synced.containsKey(p.id)) p,
];

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';

import '../../core/clock.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/luno_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../luno/luno_credential_store.dart';
import '../../core/failure.dart';

enum RestoreMode { replace, merge }

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupPreview {
  const BackupPreview({
    required this.portfolios,
    required this.transactions,
    required this.watchlists,
    required this.exportedAt,
    required this.schemaVersion,
  });
  final int portfolios;
  final int transactions;
  final int watchlists;
  final DateTime? exportedAt;
  final int schemaVersion;
}

class RestoreSummary {
  const RestoreSummary({required this.portfolios, required this.transactions, required this.skipped, required this.watchlists});
  final int portfolios;
  final int transactions;

  /// Transactions that were malformed or already present (merge mode).
  final int skipped;
  final int watchlists;
}

/// Exports and restores user data as versioned JSON, and exports transactions as CSV.
class BackupService {
  BackupService(this._portfolios, this._settings, [this._clock = const SystemClock(), this._luno, this._credentials]);

  final PortfolioRepository _portfolios;
  final SettingsRepository _settings;
  final Clock _clock;

  /// Luno connection metadata (never credentials) travels with the backup; null on platforms without Luno.
  final LunoRepository? _luno;

  /// Used to erase stored Luno keys when a restore replaces everything.
  final LunoCredentialStore? _credentials;

  static const schemaVersion = 2;
  static const _app = 'dashfolio';

  /// Settings that never leave the device (credentials) or are transient.
  static const _excludedSettings = {
    SettingKeys.lockEnabled,
    SettingKeys.lockTimeoutSeconds,
    SettingKeys.lockBiometric,
    SettingKeys.lastRefreshAt,
  };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---- export --------------------------------------------------------------

  Future<Map<String, Object?>> exportAll() async {
    final portfolios = await _portfolios.getPortfolios();
    final txs = await _portfolios.getTransactions();
    final lists = await _portfolios.getWatchlists();
    final instruments = await _portfolios.getInstruments();
    final settings = await _settings.getAll();
    final connections = await _luno?.getConnections() ?? const <LunoConnection>[];

    return {
      'app': _app,
      'schema_version': schemaVersion,
      'exported_at': _clock.now().toUtc().toIso8601String(),
      'settings': {
        for (final e in settings.entries)
          if (!_excludedSettings.contains(e.key)) e.key: e.value,
      },
      'portfolios': [
        for (final p in portfolios)
          {
            'id': p.id,
            'name': p.name,
            'description': p.description,
            'color': p.color,
            'cost_basis_method': p.costMethod.name,
            'sort_order': p.sortOrder,
            'archived': p.archived,
          },
      ],
      'transactions': [
        for (final t in txs)
          {
            'portfolio_id': t.portfolioId,
            'symbol': t.symbol,
            'type': t.type.dbName,
            'trade_date': _date(t.tradeDate),
            'quantity': t.quantity.toString(),
            'price': t.price.toString(),
            'fees': t.fees.toString(),
            'currency': t.currency,
            'fx_rate_to_base': t.fxRateToBase.toString(),
            'notes': t.notes,
            'source': t.source.name,
            'connection_id': t.connectionId,
            'external_id': t.externalId,
            'executed_at': t.executedAt?.toUtc().toIso8601String(),
          },
      ],
      'watchlists': [
        for (final w in lists) {'name': w.name, 'symbols': w.symbols},
      ],
      // Metadata only. The API key id and secret live in the platform secure store and are never exported.
      'luno_connections': [
        for (final c in connections)
          {
            'id': c.id,
            'label': c.label,
            'portfolio_id': c.portfolioId,
            'key_id_hint': c.keyIdHint,
            'home_fiat': c.homeFiat,
            'write_perm_warning': c.writePermWarning,
          },
      ],
      'instruments': [
        for (final i in instruments.values)
          {
            'symbol': i.symbol,
            'name': i.name,
            'quote_type': i.quoteType,
            'exchange': i.exchange,
            'currency': i.currency,
            'sector': i.sector,
            'industry': i.industry,
          },
      ],
    };
  }

  Future<String> exportJson() async => const JsonEncoder.withIndent('  ').convert(await exportAll());

  /// All transactions as CSV text (portfolio names resolved).
  Future<String> exportTransactionsCsv() async {
    final portfolios = {for (final p in await _portfolios.getPortfolios()) p.id: p.name};
    final txs = [...await _portfolios.getTransactions()]..sort((a, b) => a.tradeDate.compareTo(b.tradeDate));
    final rows = <List<Object?>>[
      ['date', 'portfolio', 'type', 'symbol', 'quantity', 'price', 'fees', 'currency', 'fx_rate_to_base', 'notes'],
      for (final t in txs)
        [
          _date(t.tradeDate),
          portfolios[t.portfolioId] ?? '',
          t.type.dbName,
          t.symbol ?? '',
          t.quantity.toString(),
          t.price.toString(),
          t.fees.toString(),
          t.currency,
          t.fxRateToBase.toString(),
          t.notes ?? '',
        ],
    ];
    return Csv(lineDelimiter: '\n').encode(rows);
  }

  // ---- restore -------------------------------------------------------------

  /// Parses and validates [text]; throws [BackupFormatException] on anything unusable.
  Map<String, Object?> parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const BackupFormatException('This file is not valid JSON.');
    }
    if (decoded is! Map<String, Object?> || decoded['app'] != _app) {
      throw const BackupFormatException('This is not a Dashfolio backup file.');
    }
    final v = decoded['schema_version'];
    if (v is! int) throw const BackupFormatException('The backup has no schema version.');
    if (v > schemaVersion) {
      throw BackupFormatException('This backup was made by a newer version of Dashfolio (schema $v). Update the app to restore it.');
    }
    for (final key in ['portfolios', 'transactions']) {
      if (decoded[key] is! List) throw BackupFormatException('The backup is missing "$key".');
    }
    return decoded;
  }

  BackupPreview preview(Map<String, Object?> json) => BackupPreview(
    portfolios: (json['portfolios']! as List).length,
    transactions: (json['transactions']! as List).length,
    watchlists: (json['watchlists'] as List?)?.length ?? 0,
    exportedAt: DateTime.tryParse('${json['exported_at']}'),
    schemaVersion: json['schema_version']! as int,
  );

  PortfolioTransaction? _tx(Map<String, Object?> j, int portfolioId, {int? connectionId}) {
    try {
      final type = TxType.values.where((t) => t.dbName == j['type']).firstOrNull;
      final date = DateTime.parse('${j['trade_date']}T00:00:00Z');
      final qty = Decimal.parse('${j['quantity']}');
      final price = Decimal.parse('${j['price']}');
      if (type == null) return null;
      return PortfolioTransaction(
        id: 0,
        portfolioId: portfolioId,
        symbol: j['symbol'] as String?,
        type: type,
        tradeDate: date,
        quantity: qty,
        price: price,
        fees: Decimal.parse('${j['fees'] ?? '0'}'),
        currency: (j['currency'] as String?) ?? 'USD',
        fxRateToBase: Decimal.parse('${j['fx_rate_to_base'] ?? '1'}'),
        notes: j['notes'] as String?,
        createdAt: _clock.now(),
        // A synced row is only meaningful with its connection; without one it becomes an ordinary transaction.
        source: connectionId == null
            ? (TxSource.parse(j['source'] as String?) == TxSource.csv ? TxSource.csv : TxSource.manual)
            : TxSource.luno,
        connectionId: connectionId,
        externalId: connectionId == null ? null : j['external_id'] as String?,
        executedAt: DateTime.tryParse('${j['executed_at']}'),
      );
    } on Object {
      return null;
    }
  }

  String _txKey(int portfolioId, PortfolioTransaction t) => t.connectionId != null && t.externalId != null
      ? 'luno|${t.connectionId}|${t.externalId}'
      : '$portfolioId|${t.symbol}|${t.type.dbName}|${_date(t.tradeDate)}|${t.quantity}|${t.price}|${t.fees}';

  Future<RestoreSummary> restore(Map<String, Object?> json, RestoreMode mode) async {
    if (mode == RestoreMode.replace) {
      // Keys must not outlive the connections they belonged to.
      try {
        await _credentials?.deleteAll();
      } on SecureStorageUnavailableFailure {
        // Nothing to erase without a secure store.
      }
      await _portfolios.wipeUserData();
    }

    final existingPortfolios = mode == RestoreMode.merge ? await _portfolios.getPortfolios() : const <Portfolio>[];
    final idMap = <int, int>{}; // backup id -> database id
    var createdPortfolios = 0;
    for (final raw in (json['portfolios']! as List).whereType<Map<String, Object?>>()) {
      final name = '${raw['name'] ?? 'Portfolio'}';
      final match = existingPortfolios.where((p) => p.name.toLowerCase() == name.toLowerCase()).firstOrNull;
      final backupId = raw['id'] is int ? raw['id']! as int : idMap.length + 1;
      if (match != null) {
        idMap[backupId] = match.id;
        continue;
      }
      final id = await _portfolios.createPortfolio(
        NewPortfolio(
          name: name,
          description: raw['description'] as String?,
          color: (raw['color'] as int?) ?? 0xFF3B82F6,
          costMethod: CostMethod.parse(raw['cost_basis_method'] as String?),
        ),
      );
      if (raw['archived'] == true) {
        final created = (await _portfolios.getPortfolios()).firstWhere((p) => p.id == id);
        await _portfolios.updatePortfolio(created.copyWith(archived: true));
      }
      idMap[backupId] = id;
      createdPortfolios++;
    }

    // Luno connections come back without credentials: they stay inert until the user enters a key again.
    final connectionMap = <int, int>{}; // backup connection id -> database id
    final luno = _luno;
    if (luno != null) {
      final existing = await luno.getConnections();
      for (final raw in (json['luno_connections'] as List? ?? const []).whereType<Map<String, Object?>>()) {
        final portfolioId = idMap[raw['portfolio_id']];
        final backupId = raw['id'];
        if (portfolioId == null || backupId is! int) continue;
        final already = existing.where((c) => c.portfolioId == portfolioId).firstOrNull;
        connectionMap[backupId] =
            already?.id ??
            await luno.createConnection(
              label: '${raw['label'] ?? 'Luno'}',
              portfolioId: portfolioId,
              keyIdHint: '${raw['key_id_hint'] ?? ''}',
              homeFiat: '${raw['home_fiat'] ?? 'USD'}',
              writePermWarning: raw['write_perm_warning'] != false,
            );
      }
    }

    // Existing transactions for duplicate detection in merge mode.
    final existingKeys = <String>{};
    if (mode == RestoreMode.merge) {
      for (final t in await _portfolios.getTransactions()) {
        existingKeys.add(_txKey(t.portfolioId, t));
      }
    }
    final toAdd = <PortfolioTransaction>[];
    var skipped = 0;
    for (final raw in (json['transactions']! as List)) {
      if (raw is! Map<String, Object?>) {
        skipped++;
        continue;
      }
      final pid = idMap[raw['portfolio_id']];
      final backupConnection = raw['connection_id'];
      final tx = pid == null ? null : _tx(raw, pid, connectionId: backupConnection is int ? connectionMap[backupConnection] : null);
      if (tx == null) {
        skipped++;
        continue;
      }
      final key = _txKey(pid!, tx);
      if (mode == RestoreMode.merge && !existingKeys.add(key)) {
        skipped++;
        continue;
      }
      toAdd.add(tx);
    }
    if (toAdd.isNotEmpty) await _portfolios.addTransactions(toAdd);

    // Watchlists: match by name, add missing symbols.
    final existingLists = mode == RestoreMode.merge ? await _portfolios.getWatchlists() : const <Watchlist>[];
    var lists = 0;
    for (final raw in (json['watchlists'] as List? ?? const []).whereType<Map<String, Object?>>()) {
      final name = '${raw['name'] ?? 'Watchlist'}';
      final symbols = [for (final s in (raw['symbols'] as List? ?? const [])) '$s'];
      final match = existingLists.where((w) => w.name.toLowerCase() == name.toLowerCase()).firstOrNull;
      final id = match?.id ?? await _portfolios.createWatchlist(name);
      if (match == null) lists++;
      for (final s in symbols) {
        if (match == null || !match.symbols.contains(s)) await _portfolios.addToWatchlist(id, s);
      }
    }

    for (final raw in (json['instruments'] as List? ?? const []).whereType<Map<String, Object?>>()) {
      final symbol = raw['symbol'] as String?;
      if (symbol == null) continue;
      await _portfolios.upsertInstrument(
        Instrument(
          symbol: symbol,
          name: (raw['name'] as String?) ?? symbol,
          quoteType: raw['quote_type'] as String?,
          exchange: raw['exchange'] as String?,
          currency: (raw['currency'] as String?) ?? 'USD',
          sector: raw['sector'] as String?,
          industry: raw['industry'] as String?,
        ),
      );
    }

    if (mode == RestoreMode.replace) {
      final settings = json['settings'];
      if (settings is Map) {
        for (final e in settings.entries) {
          final k = '${e.key}';
          if (!_excludedSettings.contains(k) && e.value is String) await _settings.set(k, e.value as String);
        }
      }
    }
    return RestoreSummary(portfolios: createdPortfolios, transactions: toAdd.length, skipped: skipped, watchlists: lists);
  }
}

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:logging/logging.dart';

import '../../core/clock.dart';
import '../../core/decimal_ext.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/luno_repository.dart';
import '../../domain/repositories/market_data_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/services/fx.dart';
import '../../domain/services/holdings_engine.dart';
import '../../domain/services/luno_ledger_mapper.dart';
import '../../domain/services/luno_reconciliation.dart';
import 'luno_client.dart';
import 'luno_mappers.dart';

final _log = Logger('LunoSync');

/// Builds the client for a connection (credentials are fetched from the secure store per request).
typedef LunoClientFactory = LunoClient Function(int connectionId);

class LunoSyncProgress {
  const LunoSyncProgress({required this.phase, this.accountsDone = 0, this.accountsTotal = 0, this.rowsFetched = 0});

  /// `balances` | `ledger` | `mapping` | `reconciling`.
  final String phase;
  final int accountsDone;
  final int accountsTotal;
  final int rowsFetched;
}

class LunoSyncResult {
  const LunoSyncResult({
    this.rowsFetched = 0,
    this.transactions = 0,
    this.unrecognised = 0,
    this.deferred = 0,
    this.mismatches = const [],
    this.warnings = const [],
    this.failure,
    this.skipped = false,
  });

  final int rowsFetched;

  /// Transactions written or refreshed by this run.
  final int transactions;
  final int unrecognised;
  final int deferred;
  final List<LunoAssetMismatch> mismatches;
  final List<String> warnings;
  final AppFailure? failure;

  /// True when nothing was attempted (already syncing, or the connection cannot sync).
  final bool skipped;

  bool get ok => failure == null && !skipped;
}

/// Syncs one Luno connection into its portfolio.
///
/// 1. `GET /balance`; accounts whose balances equal the last snapshot are skipped, so an idle sync costs one call.
/// 2. Each changed account's ledger is paged from its cursor into the local staging table; the cursor is committed
///    per page, so an interrupted first sync resumes where it stopped.
/// 3. Staged rows are mapped (pure [LunoLedgerMapper]) and upserted by external id: re-running is idempotent.
/// 4. The replayed quantities are reconciled against Luno's balances; a mismatch marks the connection `needsReview`
///    and is never adjusted away.
///
/// Failures never discard cached data. A rejected key marks the connection revoked.
class LunoSyncService {
  LunoSyncService({
    required this.luno,
    required this.portfolios,
    required this.market,
    required this.clientFor,
    this.clock = const SystemClock(),
    this.mapper = const LunoLedgerMapper(),
    this.engine = const HoldingsEngine(),
    this.ledgerPageSize = LunoClient.pageSize,
  });

  final LunoRepository luno;
  final PortfolioRepository portfolios;
  final MarketDataRepository market;
  final LunoClientFactory clientFor;
  final Clock clock;
  final LunoLedgerMapper mapper;
  final HoldingsEngine engine;

  /// Ledger rows requested per call (the API allows at most 1000).
  final int ledgerPageSize;

  final Map<int, Future<LunoSyncResult>> _running = {};

  /// Runs a sync for [connectionId], or joins the one already in flight.
  Future<LunoSyncResult> sync(
    int connectionId, {
    required String baseCurrency,
    void Function(LunoSyncProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) {
    final existing = _running[connectionId];
    if (existing != null) return existing;
    final run = _sync(connectionId, baseCurrency, onProgress, isCancelled ?? () => false);
    _running[connectionId] = run;
    run.whenComplete(() {
      _running.remove(connectionId); // block body: returning the future would make it await itself
    }).ignore();
    return run;
  }

  Future<LunoSyncResult> _sync(
    int connectionId,
    String baseCurrency,
    void Function(LunoSyncProgress)? onProgress,
    bool Function() isCancelled,
  ) async {
    final conn = await luno.getConnection(connectionId);
    if (conn == null || !conn.status.canSync) return const LunoSyncResult(skipped: true);
    await luno.setStatus(connectionId, LunoConnectionStatus.syncing, error: null);
    void progress(LunoSyncProgress p) => onProgress?.call(p);

    try {
      final client = clientFor(connectionId);

      // ---- 1. balances ----------------------------------------------------------------------------------------------
      progress(const LunoSyncProgress(phase: 'balances'));
      final accounts = await client.balances();
      final cursors = await luno.getCursors(connectionId);

      // ---- 2. ledgers -----------------------------------------------------------------------------------------------
      var rowsFetched = 0;
      var accountsDone = 0;
      for (final account in accounts) {
        if (isCancelled()) throw const NetworkFailure('Sync cancelled');
        final cursor = cursors[account.accountId];
        // A connection under review is re-read in full: its ledger may simply be behind the balances.
        if (cursor != null && cursor.matches(account) && conn.status != LunoConnectionStatus.needsReview) {
          accountsDone++;
          continue;
        }
        var lastRow = cursor?.lastRowIndex ?? 0;
        while (true) {
          final page = await client.ledger(account.accountId, minRow: lastRow + 1, maxRow: lastRow + 1 + ledgerPageSize);
          if (page.isEmpty) break;
          await luno.stageRows(connectionId, [for (final e in page) _stage(e, account)]);
          rowsFetched += page.length;
          lastRow = page.map((e) => e.rowIndex).reduce((a, b) => a > b ? a : b);
          await luno.upsertCursor(_cursor(connectionId, account, cursor, lastRow, snapshot: false));
          progress(LunoSyncProgress(phase: 'ledger', accountsDone: accountsDone, accountsTotal: accounts.length, rowsFetched: rowsFetched));
          if (page.length < ledgerPageSize) break;
          if (isCancelled()) throw const NetworkFailure('Sync cancelled');
        }
        // Only now does the cursor claim to match the balances: an interrupted fetch re-checks this account.
        await luno.upsertCursor(_cursor(connectionId, account, cursor, lastRow, snapshot: true));
        accountsDone++;
      }

      // ---- 3. mapping ----------------------------------------------------------------------------------------------
      progress(LunoSyncProgress(phase: 'mapping', accountsDone: accountsDone, accountsTotal: accounts.length, rowsFetched: rowsFetched));
      final mapping = await _map(conn, baseCurrency);

      // ---- 4. reconciliation ---------------------------------------------------------------------------------------
      progress(
        LunoSyncProgress(phase: 'reconciling', accountsDone: accountsDone, accountsTotal: accounts.length, rowsFetched: rowsFetched),
      );
      final synced = await luno.syncedTransactions(connectionId);
      final portfolio = (await portfolios.getPortfolios()).where((p) => p.id == conn.portfolioId).firstOrNull;
      final replay = engine.replay(synced, portfolio?.costMethod ?? CostMethod.average);
      final mismatches = reconcileLuno(accounts: accounts, heldBySymbol: {for (final p in replay.positions.values) p.symbol: p.quantity});
      final unrecognisedTotal = (await luno.stagedRows(connectionId, states: {'unrecognised'})).length;

      final waiting = mapping.deferred.length;
      final LunoConnectionStatus status;
      String? note;
      if (mismatches.isEmpty) {
        status = LunoConnectionStatus.ok;
        if (waiting > 0) note = '$waiting ledger rows are waiting for a price or their counterpart';
      } else if (waiting > 0) {
        // Rows still in flight explain the difference; re-check on the next sync before alarming the user.
        status = LunoConnectionStatus.ok;
        note = '$waiting ledger rows are waiting for a price or their counterpart';
      } else {
        status = LunoConnectionStatus.needsReview;
        note = mismatches.map((m) => m.toString()).join('; ');
      }
      await luno.setStatus(connectionId, status, error: note, lastSyncAt: clock.now(), unrecognisedRows: unrecognisedTotal);
      return LunoSyncResult(
        rowsFetched: rowsFetched,
        transactions: mapping.transactions.length,
        unrecognised: unrecognisedTotal,
        deferred: waiting,
        mismatches: mismatches,
        warnings: mapping.warnings,
      );
    } on AppFailure catch (f) {
      _log.warning('Sync of connection $connectionId failed: ${f.runtimeType}');
      final status = switch (f) {
        KeyRevokedFailure() => LunoConnectionStatus.revoked,
        CredentialsMissingFailure() => LunoConnectionStatus.credentialsMissing,
        _ => LunoConnectionStatus.error,
      };
      await luno.setStatus(connectionId, status, error: f.message);
      return LunoSyncResult(failure: f);
    }
  }

  LunoStagedRow _stage(LunoLedgerEntry e, LunoAccount account) => LunoStagedRow(
    accountId: e.accountId.isEmpty ? account.accountId : e.accountId,
    rowIndex: e.rowIndex,
    timestamp: e.timestamp,
    payloadJson: jsonEncode(_entryJson(e)),
  );

  LunoAccountCursor _cursor(int connectionId, LunoAccount a, LunoAccountCursor? previous, int lastRow, {required bool snapshot}) =>
      LunoAccountCursor(
        connectionId: connectionId,
        accountId: a.accountId,
        asset: a.asset,
        accountType: a.accountType,
        lastRowIndex: lastRow,
        balanceSnapshot: snapshot ? a.balance : (previous?.balanceSnapshot ?? Decimal.zero),
        reservedSnapshot: snapshot ? a.reserved : (previous?.reservedSnapshot ?? Decimal.zero),
        unconfirmedSnapshot: snapshot ? a.unconfirmed : (previous?.unconfirmedSnapshot ?? Decimal.zero),
        syncedAt: snapshot ? clock.now() : previous?.syncedAt,
      );

  // ---- staging <-> entries ---------------------------------------------------------------------------------------

  /// Lossless JSON form of an entry (decimals as strings), parsed back by [_entryFrom].
  Map<String, Object?> _entryJson(LunoLedgerEntry e) => {
    'account_id': e.accountId,
    'row_index': e.rowIndex,
    'timestamp': e.timestamp.millisecondsSinceEpoch,
    'currency': e.asset,
    'kind': switch (e.kind) {
      LunoLedgerKind.fee => 'FEE',
      LunoLedgerKind.transfer => 'TRANSFER',
      LunoLedgerKind.exchange => 'EXCHANGE',
      LunoLedgerKind.interest => 'INTEREST',
      LunoLedgerKind.unknown => 'UNKNOWN',
    },
    'balance_delta': e.balanceDelta.toString(),
    'available_delta': e.availableDelta?.toString(),
    'balance': e.balance?.toString(),
    'description': e.description,
    'reference': e.reference,
    'detail_fields': {
      if (e.tradePair != null)
        'trade_details': {
          'pair': e.tradePair,
          'price': e.tradePrice?.toString(),
          'volume': e.tradeVolume?.toString(),
          'sequence': e.tradeSequence,
        },
      if (e.txId != null) 'crypto_details': {'txid': e.txId},
    },
  };

  LunoLedgerEntry? _entryFrom(LunoStagedRow row) {
    try {
      final json = (jsonDecode(row.payloadJson) as Map).cast<String, Object?>();
      return LunoMappers.ledger({
        'transactions': [json],
      }, accountId: row.accountId).firstOrNull;
    } on Object {
      return null;
    }
  }

  // ---- mapping ---------------------------------------------------------------------------------------------------

  Future<LunoMapResult> _map(LunoConnection conn, String baseCurrency) async {
    final staged = await luno.stagedRows(conn.id);
    final entries = <LunoLedgerEntry>[];
    final broken = <String, String>{};
    for (final row in staged) {
      final e = _entryFrom(row);
      e == null ? broken[row.key] = 'unreadable' : entries.add(e);
    }
    if (entries.isEmpty && broken.isEmpty) {
      return const LunoMapResult(transactions: [], mapped: {}, unrecognised: {}, deferred: {}, warnings: []);
    }

    final now = clock.now();
    final earliest = entries.isEmpty ? now : entries.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
    final from = dateOnly(earliest).subtract(const Duration(days: 10));

    // Fiat prices of the crypto assets involved, from the same daily series the app charts.
    final assets = {
      for (final e in entries)
        if (!isLunoFiat(e.asset)) e.asset,
    };
    final priceSeries = <String, FxSeries>{};
    for (final asset in assets) {
      final r = await market.dailyHistory(lunoSymbol('$asset${conn.homeFiat}'), from);
      if (r case Ok(:final value) when value.candles.isNotEmpty) {
        priceSeries[asset] = FxSeries([for (final c in value.candles) c.time], [for (final c in value.candles) dec(c.close)]);
      }
    }

    // Historical FX to the base currency for every currency a transaction can carry.
    final currencies = {
      conn.homeFiat,
      for (final e in entries)
        if (isLunoFiat(e.asset)) e.asset,
    }..remove(baseCurrency);
    final fxSeries = <String, FxSeries>{};
    for (final c in currencies) {
      final r = await market.dailyHistory(fxSymbol(c, baseCurrency), from);
      if (r case Ok(:final value) when value.candles.isNotEmpty) {
        fxSeries[c] = FxSeries([for (final x in value.candles) x.time], [for (final x in value.candles) dec(x.close)]);
      }
    }
    final currentFx = QuoteFxRates({
      for (final q in (await market.quotesSnapshot()).values)
        if (q.symbol.endsWith('=X') && q.price != null) q.symbol: q.price!,
    });

    final result = mapper.map(
      entries,
      LunoMapContext(
        portfolioId: conn.portfolioId,
        connectionId: conn.id,
        homeFiat: conn.homeFiat,
        now: now,
        priceOf: (asset, at) => priceSeries[asset]?.at(dateOnly(at.toUtc())),
        fxToBase: (currency, at) {
          if (currency == baseCurrency) return Decimal.one;
          return fxSeries[currency]?.at(dateOnly(at.toUtc())) ?? currentFx.rate(currency, baseCurrency) ?? Decimal.one;
        },
      ),
    );

    // Persist atomically enough: transactions first, then row states, so a crash re-maps (idempotently) rather than loses rows.
    await luno.upsertSyncedTransactions(conn.id, result.transactions);
    await luno.setRowStates(conn.id, {
      for (final k in result.mapped) k: 'mapped',
      for (final k in result.unrecognised.keys) k: 'unrecognised',
      for (final k in broken.keys) k: 'unrecognised',
    });
    await _rememberInstruments(result.transactions);
    return result;
  }

  Future<void> _rememberInstruments(List<PortfolioTransaction> txs) async {
    final seen = <String>{};
    for (final t in txs) {
      final symbol = t.symbol;
      if (symbol == null || !isLunoSymbol(symbol) || !seen.add(symbol)) continue;
      final asset = lunoSymbolAsset(symbol);
      await portfolios.upsertInstrument(
        Instrument(
          symbol: symbol,
          name: asset == null ? symbol : lunoAssetName(asset),
          quoteType: 'CRYPTOCURRENCY',
          exchange: 'Luno',
          currency: t.currency,
        ),
      );
    }
  }

  /// Forgets all derived transactions and re-maps every staged row (after the mapping improved). Nothing is refetched.
  Future<void> remapAll(int connectionId, {required String baseCurrency}) async {
    await luno.deleteSyncedTransactions(connectionId);
    await luno.resetStagedStates(connectionId);
    final conn = await luno.getConnection(connectionId);
    if (conn != null) await _map(conn, baseCurrency);
  }
}

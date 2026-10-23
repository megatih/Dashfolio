import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/luno.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/luno_repository.dart';
import '../db/app_database.dart';

class LunoRepositoryImpl implements LunoRepository {
  LunoRepositoryImpl(this._db);

  final AppDatabase _db;

  LunoConnection _connection(LunoConnectionRow r) => LunoConnection(
    id: r.id,
    label: r.label,
    portfolioId: r.portfolioId,
    keyIdHint: r.keyIdHint,
    homeFiat: r.homeFiat,
    status: LunoConnectionStatus.parse(r.status),
    lastSyncAt: r.lastSyncAt,
    lastError: r.lastError,
    writePermWarning: r.writePermWarning,
    unrecognisedRows: r.unrecognisedRows,
    createdAt: r.createdAt,
  );

  SimpleSelectStatement<$LunoConnectionsTable, LunoConnectionRow> _query() =>
      _db.select(_db.lunoConnections)..orderBy([(t) => OrderingTerm.asc(t.id)]);

  @override
  Stream<List<LunoConnection>> watchConnections() => _query().watch().map((rows) => rows.map(_connection).toList());

  @override
  Future<List<LunoConnection>> getConnections() async => (await _query().get()).map(_connection).toList();

  @override
  Future<LunoConnection?> getConnection(int id) async {
    final r = await (_db.select(_db.lunoConnections)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _connection(r);
  }

  @override
  Future<int> createConnection({
    required String label,
    required int portfolioId,
    required String keyIdHint,
    required String homeFiat,
    LunoConnectionStatus status = LunoConnectionStatus.credentialsMissing,
    bool writePermWarning = false,
  }) => _db
      .into(_db.lunoConnections)
      .insert(
        LunoConnectionsCompanion.insert(
          label: label.trim(),
          portfolioId: portfolioId,
          keyIdHint: Value(keyIdHint),
          homeFiat: homeFiat,
          status: Value(status.dbName),
          writePermWarning: Value(writePermWarning),
          createdAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<void> updateConnection(LunoConnection c) => (_db.update(_db.lunoConnections)..where((t) => t.id.equals(c.id))).write(
    LunoConnectionsCompanion(
      label: Value(c.label.trim()),
      keyIdHint: Value(c.keyIdHint),
      homeFiat: Value(c.homeFiat),
      writePermWarning: Value(c.writePermWarning),
    ),
  );

  @override
  Future<void> setStatus(int id, LunoConnectionStatus status, {String? error, DateTime? lastSyncAt, int? unrecognisedRows}) =>
      (_db.update(_db.lunoConnections)..where((t) => t.id.equals(id))).write(
        LunoConnectionsCompanion(
          status: Value(status.dbName),
          lastError: Value(error),
          lastSyncAt: lastSyncAt == null ? const Value.absent() : Value(lastSyncAt),
          unrecognisedRows: unrecognisedRows == null ? const Value.absent() : Value(unrecognisedRows),
        ),
      );

  @override
  Future<void> deleteConnection(int id) => _db.transaction(() async {
    // Staged rows and cursors cascade; synced transactions keep existing with their connection reference cleared.
    await (_db.delete(_db.lunoConnections)..where((t) => t.id.equals(id))).go();
  });

  // ---- sync state ----------------------------------------------------------

  @override
  Future<Map<String, LunoAccountCursor>> getCursors(int connectionId) async => {
    for (final r in await (_db.select(_db.lunoAccountCursors)..where((t) => t.connectionId.equals(connectionId))).get())
      r.accountId: LunoAccountCursor(
        connectionId: r.connectionId,
        accountId: r.accountId,
        asset: r.asset,
        accountType: r.accountType,
        lastRowIndex: r.lastRowIndex,
        balanceSnapshot: r.balanceSnapshot,
        reservedSnapshot: r.reservedSnapshot,
        unconfirmedSnapshot: r.unconfirmedSnapshot,
        syncedAt: r.syncedAt,
      ),
  };

  @override
  Future<void> upsertCursor(LunoAccountCursor c) => _db
      .into(_db.lunoAccountCursors)
      .insertOnConflictUpdate(
        LunoAccountCursorsCompanion.insert(
          connectionId: c.connectionId,
          accountId: c.accountId,
          asset: c.asset,
          accountType: Value(c.accountType),
          lastRowIndex: Value(c.lastRowIndex),
          balanceSnapshot: Value(c.balanceSnapshot),
          reservedSnapshot: Value(c.reservedSnapshot),
          unconfirmedSnapshot: Value(c.unconfirmedSnapshot),
          syncedAt: Value(c.syncedAt),
        ),
      );

  @override
  Future<int> stageRows(int connectionId, List<LunoStagedRow> rows) async {
    if (rows.isEmpty) return 0;
    final before = await _count(connectionId);
    await _db.batch((b) {
      b.insertAll(_db.lunoLedgerRows, [
        for (final r in rows)
          LunoLedgerRowsCompanion.insert(
            connectionId: connectionId,
            accountId: r.accountId,
            rowIndex: r.rowIndex,
            timestampMs: r.timestamp.millisecondsSinceEpoch,
            payloadJson: r.payloadJson,
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
    return await _count(connectionId) - before;
  }

  Future<int> _count(int connectionId) async {
    final c = _db.lunoLedgerRows.rowIndex.count();
    final q = _db.selectOnly(_db.lunoLedgerRows)
      ..addColumns([c])
      ..where(_db.lunoLedgerRows.connectionId.equals(connectionId));
    return await q.map((r) => r.read(c)).getSingle() ?? 0;
  }

  @override
  Future<List<LunoStagedRow>> stagedRows(int connectionId, {Set<String> states = const {'pending', 'unrecognised'}}) async {
    final q = _db.select(_db.lunoLedgerRows)
      ..where((t) => t.connectionId.equals(connectionId) & t.state.isIn(states))
      ..orderBy([(t) => OrderingTerm.asc(t.timestampMs), (t) => OrderingTerm.asc(t.accountId), (t) => OrderingTerm.asc(t.rowIndex)]);
    return [
      for (final r in await q.get())
        LunoStagedRow(
          accountId: r.accountId,
          rowIndex: r.rowIndex,
          timestamp: DateTime.fromMillisecondsSinceEpoch(r.timestampMs, isUtc: true),
          payloadJson: r.payloadJson,
          state: r.state,
        ),
    ];
  }

  @override
  Future<void> setRowStates(int connectionId, Map<String, String> stateByKey) => _db.batch((b) {
    stateByKey.forEach((key, state) {
      final i = key.lastIndexOf(':');
      final account = key.substring(0, i);
      final row = int.parse(key.substring(i + 1));
      b.update(
        _db.lunoLedgerRows,
        LunoLedgerRowsCompanion(state: Value(state)),
        where: (t) => t.connectionId.equals(connectionId) & t.accountId.equals(account) & t.rowIndex.equals(row),
      );
    });
  });

  @override
  Future<void> resetStagedStates(int connectionId) => (_db.update(
    _db.lunoLedgerRows,
  )..where((t) => t.connectionId.equals(connectionId))).write(const LunoLedgerRowsCompanion(state: Value('pending')));

  // ---- synced transactions -------------------------------------------------

  PortfolioTransaction _tx(TransactionRow r) => PortfolioTransaction(
    id: r.id,
    portfolioId: r.portfolioId,
    symbol: r.symbol,
    type: TxType.parse(r.type),
    tradeDate: r.tradeDate,
    quantity: r.quantity,
    price: r.price,
    fees: r.fees,
    currency: r.currency,
    fxRateToBase: r.fxRateToBase,
    notes: r.notes,
    importBatchId: r.importBatchId,
    createdAt: r.createdAt,
    source: TxSource.parse(r.source),
    connectionId: r.connectionId,
    externalId: r.externalId,
    executedAt: r.executedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.executedAt!, isUtc: true),
  );

  @override
  Future<List<PortfolioTransaction>> syncedTransactions(int connectionId) async =>
      (await (_db.select(_db.transactions)..where((t) => t.connectionId.equals(connectionId))).get()).map(_tx).toList();

  @override
  Future<void> upsertSyncedTransactions(int connectionId, List<PortfolioTransaction> txs) => _db.transaction(() async {
    for (final t in txs) {
      final fields = TransactionsCompanion(
        portfolioId: Value(t.portfolioId),
        symbol: Value(t.symbol),
        type: Value(t.type.dbName),
        tradeDate: Value(dateOnly(t.tradeDate)),
        quantity: Value(t.quantity),
        price: Value(t.price),
        fees: Value(t.fees),
        currency: Value(t.currency),
        fxRateToBase: Value(t.fxRateToBase),
        source: const Value('luno'),
        connectionId: Value(connectionId),
        externalId: Value(t.externalId),
        executedAt: Value(t.executedAt?.millisecondsSinceEpoch),
      );
      await _db
          .into(_db.transactions)
          .insert(
            fields.copyWith(notes: Value(t.notes), createdAt: Value(t.createdAt)),
            // Re-syncing refreshes the numbers but keeps the user's notes and the original creation time.
            onConflict: DoUpdate((_) => fields, target: [_db.transactions.connectionId, _db.transactions.externalId]),
          );
    }
  });

  @override
  Future<void> detachSyncedTransactions(int connectionId) =>
      (_db.update(_db.transactions)..where((t) => t.connectionId.equals(connectionId))).write(
        const TransactionsCompanion(source: Value('manual'), connectionId: Value(null), externalId: Value(null)),
      );

  @override
  Future<int> deleteSyncedTransactions(int connectionId) =>
      (_db.delete(_db.transactions)..where((t) => t.connectionId.equals(connectionId))).go();
}

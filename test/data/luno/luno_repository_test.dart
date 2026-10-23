import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:dashfolio/domain/repositories/luno_repository.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LunoRepositoryImpl repo;
  late PortfolioRepositoryImpl portfolios;
  late int pid;
  late int cid;

  PortfolioTransaction synced(String ext, {String? notes, num qty = 1, num price = 100}) => PortfolioTransaction(
    id: 0,
    portfolioId: pid,
    symbol: 'LUNO:XBTMYR',
    type: TxType.buy,
    tradeDate: DateTime.utc(2024, 1, 2),
    quantity: Decimal.parse('$qty'),
    price: Decimal.parse('$price'),
    fees: Decimal.zero,
    currency: 'MYR',
    fxRateToBase: Decimal.one,
    notes: notes,
    createdAt: DateTime.utc(2024, 1, 3),
    source: TxSource.luno,
    connectionId: cid,
    externalId: ext,
    executedAt: DateTime.utc(2024, 1, 2, 5),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LunoRepositoryImpl(db);
    portfolios = PortfolioRepositoryImpl(db);
    pid = await portfolios.createPortfolio(const NewPortfolio(name: 'Luno'));
    cid = await repo.createConnection(label: 'Main', portfolioId: pid, keyIdHint: 'abcd', homeFiat: 'MYR');
  });
  tearDown(() => db.close());

  group('connections', () {
    test('create, read, update and set status', () async {
      final c = (await repo.getConnection(cid))!;
      expect(
        (c.label, c.homeFiat, c.keyIdHint, c.status, c.portfolioId),
        ('Main', 'MYR', 'abcd', LunoConnectionStatus.credentialsMissing, pid),
      );
      await repo.updateConnection(c.copyWith(label: ' Renamed ', homeFiat: 'ZAR', writePermWarning: true));
      await repo.setStatus(
        cid,
        LunoConnectionStatus.needsReview,
        error: 'XBT differs',
        lastSyncAt: DateTime.utc(2024, 5, 1),
        unrecognisedRows: 2,
      );
      final u = (await repo.getConnection(cid))!;
      expect(
        (u.label, u.homeFiat, u.writePermWarning, u.status, u.lastError, u.lastSyncAt?.toUtc(), u.unrecognisedRows),
        ('Renamed', 'ZAR', true, LunoConnectionStatus.needsReview, 'XBT differs', DateTime.utc(2024, 5, 1), 2),
      );
      await repo.setStatus(cid, LunoConnectionStatus.ok);
      final ok = (await repo.getConnection(cid))!;
      expect(
        (ok.lastError, ok.lastSyncAt?.toUtc(), ok.unrecognisedRows),
        (null, DateTime.utc(2024, 5, 1), 2),
        reason: 'error is cleared; omitted fields are kept',
      );
      expect((await repo.watchConnections().first).length, 1);
      expect(await repo.getConnection(999), isNull);
    });

    test('deleting a portfolio removes its connection, cursors and staged rows', () async {
      await repo.upsertCursor(
        LunoAccountCursor(
          connectionId: cid,
          accountId: 'a',
          asset: 'XBT',
          balanceSnapshot: Decimal.one,
          reservedSnapshot: Decimal.zero,
          unconfirmedSnapshot: Decimal.zero,
        ),
      );
      await repo.stageRows(cid, [LunoStagedRow(accountId: 'a', rowIndex: 1, timestamp: DateTime.utc(2024), payloadJson: '{}')]);
      await portfolios.deletePortfolio(pid);
      expect(await repo.getConnections(), isEmpty);
      expect(await db.select(db.lunoAccountCursors).get(), isEmpty);
      expect(await db.select(db.lunoLedgerRows).get(), isEmpty);
    });
  });

  group('cursors and staging', () {
    test('cursors upsert and read back with exact decimals', () async {
      LunoAccountCursor cursor(int row, String balance) => LunoAccountCursor(
        connectionId: cid,
        accountId: 'a',
        asset: 'XBT',
        accountType: 'TRANSACTIONAL',
        lastRowIndex: row,
        balanceSnapshot: Decimal.parse(balance),
        reservedSnapshot: Decimal.parse('0.001'),
        unconfirmedSnapshot: Decimal.zero,
        syncedAt: DateTime.utc(2024, 2, 2),
      );
      await repo.upsertCursor(cursor(5, '0.01395'));
      await repo.upsertCursor(cursor(9, '0.02'));
      final got = (await repo.getCursors(cid))['a']!;
      expect(
        (got.lastRowIndex, got.balanceSnapshot, got.reservedSnapshot, got.syncedAt?.toUtc()),
        (9, Decimal.parse('0.02'), Decimal.parse('0.001'), DateTime.utc(2024, 2, 2)),
      );
    });

    test('staging ignores rows it already has and keeps their state', () async {
      LunoStagedRow row(int i) => LunoStagedRow(accountId: 'a', rowIndex: i, timestamp: DateTime.utc(2024, 1, i), payloadJson: '{"i":$i}');
      expect(await repo.stageRows(cid, [row(1), row(2)]), 2);
      await repo.setRowStates(cid, {'a:1': 'mapped'});
      expect(await repo.stageRows(cid, [row(1), row(2), row(3)]), 1);
      expect((await repo.stagedRows(cid)).map((r) => r.key), ['a:2', 'a:3']);
      expect((await repo.stagedRows(cid, states: {'mapped'})).single.key, 'a:1');
      await repo.resetStagedStates(cid);
      expect((await repo.stagedRows(cid)).length, 3);
      expect(await repo.stageRows(cid, const []), 0);
    });

    test('rows come back oldest first, across accounts', () async {
      await repo.stageRows(cid, [
        LunoStagedRow(accountId: 'b', rowIndex: 1, timestamp: DateTime.utc(2024, 1, 2), payloadJson: '{}'),
        LunoStagedRow(accountId: 'a', rowIndex: 7, timestamp: DateTime.utc(2024, 1, 3), payloadJson: '{}'),
        LunoStagedRow(accountId: 'a', rowIndex: 3, timestamp: DateTime.utc(2024, 1, 1), payloadJson: '{}'),
      ]);
      expect((await repo.stagedRows(cid)).map((r) => r.key), ['a:3', 'b:1', 'a:7']);
    });
  });

  group('synced transactions', () {
    test('upsert inserts, then refreshes numbers by external id while keeping the user notes and creation time', () async {
      await repo.upsertSyncedTransactions(cid, [synced('x1', notes: 'from sync'), synced('x2')]);
      final first = (await repo.syncedTransactions(cid)).firstWhere((t) => t.externalId == 'x1');
      await portfolios.updateTransaction(
        PortfolioTransaction(
          id: first.id,
          portfolioId: pid,
          symbol: first.symbol,
          type: first.type,
          tradeDate: first.tradeDate,
          quantity: first.quantity,
          price: first.price,
          fees: first.fees,
          currency: first.currency,
          fxRateToBase: first.fxRateToBase,
          notes: 'my note',
          createdAt: first.createdAt,
          source: TxSource.luno,
          connectionId: cid,
          externalId: 'x1',
          executedAt: first.executedAt,
        ),
      );
      await repo.upsertSyncedTransactions(cid, [synced('x1', qty: 2, price: 150, notes: 'overwrite attempt'), synced('x2'), synced('x3')]);
      final all = await repo.syncedTransactions(cid);
      expect(all.length, 3);
      final x1 = all.firstWhere((t) => t.externalId == 'x1');
      expect((x1.quantity, x1.price, x1.notes, x1.id), (Decimal.parse('2'), Decimal.parse('150'), 'my note', first.id));
      expect(x1.executedAt, DateTime.utc(2024, 1, 2, 5));
      expect(x1.source, TxSource.luno);
    });

    test('detach turns them into ordinary manual rows; delete removes only this connection\'s', () async {
      final other = await repo.createConnection(label: 'Other', portfolioId: pid, keyIdHint: 'zzzz', homeFiat: 'ZAR');
      await repo.upsertSyncedTransactions(cid, [synced('a')]);
      await repo.upsertSyncedTransactions(other, [synced('a').copyWithConnection(other)]);
      expect((await repo.syncedTransactions(other)).length, 1, reason: 'same external id under another connection is a different row');

      await repo.detachSyncedTransactions(cid);
      final all = await portfolios.getTransactions();
      final detached = all.firstWhere((t) => t.connectionId == null);
      expect((detached.source, detached.externalId), (TxSource.manual, null));
      expect(await repo.syncedTransactions(cid), isEmpty);

      expect(await repo.deleteSyncedTransactions(other), 1);
      expect((await portfolios.getTransactions()).length, 1);
    });

    test('deleting a connection leaves its transactions in place without a connection reference', () async {
      await repo.upsertSyncedTransactions(cid, [synced('a')]);
      await repo.deleteConnection(cid);
      final tx = (await portfolios.getTransactions()).single;
      expect(tx.connectionId, isNull);
    });
  });
}

extension on PortfolioTransaction {
  PortfolioTransaction copyWithConnection(int connection) => PortfolioTransaction(
    id: 0,
    portfolioId: portfolioId,
    symbol: symbol,
    type: type,
    tradeDate: tradeDate,
    quantity: quantity,
    price: price,
    fees: fees,
    currency: currency,
    fxRateToBase: fxRateToBase,
    notes: notes,
    createdAt: createdAt,
    source: source,
    connectionId: connection,
    externalId: externalId,
    executedAt: executedAt,
  );
}

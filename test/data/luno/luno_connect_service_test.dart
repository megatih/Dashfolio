import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/luno/luno_connect_service.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_luno_credentials.dart';
import '../../support/fake_luno_server.dart';

import 'package:dashfolio/core/decimal_ext.dart';

const _creds = LunoCredentials(keyId: 'abcd1234keyid', keySecret: 'SUPERSECRET-0123456789');

void main() {
  late AppDatabase db;
  late FakeLunoServer server;
  late FakeLunoCredentialStore store;
  late LunoRepositoryImpl luno;
  late PortfolioRepositoryImpl portfolios;
  late LunoConnectService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeLunoServer();
    store = FakeLunoCredentialStore();
    luno = LunoRepositoryImpl(db);
    portfolios = PortfolioRepositoryImpl(db);
    service = LunoConnectService(store: store, luno: luno, portfolios: portfolios, dio: Dio()..httpClientAdapter = server.adapter);
  });
  tearDown(() => db.close());

  Future<int> connectOk({String label = 'Main', bool confirmed = false}) async {
    final check = await service.verify(_creds);
    return service.connect(
      credentials: _creds,
      check: check,
      label: label,
      homeFiat: 'MYR',
      costMethod: CostMethod.fifo,
      sendPermissionConfirmedAbsent: confirmed,
    );
  }

  group('verify', () {
    test('a read-only key is accepted and its accounts are returned', () async {
      final check = await service.verify(_creds);
      expect(check.acceptable, isTrue);
      expect(check.accounts.map((a) => a.asset), ['MYR', 'XBT', 'ETH']);
    });

    test('keys that can place orders, cancel withdrawals or whose probes are inconclusive are not acceptable', () async {
      server.canStopOrders = true;
      expect((await service.verify(_creds)).acceptable, isFalse);
      server.canStopOrders = false;
      server.canCancelWithdrawals = true;
      expect((await service.verify(_creds)).hasDangerousWrites, isTrue);
      server.canCancelWithdrawals = false;
      server.stopOrderOverride = 400;
      final odd = await service.verify(_creds);
      expect((odd.inconclusive, odd.acceptable), (true, false));
    });

    test('a key without the permissions the sync needs is not acceptable', () async {
      server.canReadOrders = false;
      expect((await service.verify(_creds)).acceptable, isFalse);
      server.canReadOrders = true;
      server.canReadTransactions = false;
      expect((await service.verify(_creds)).acceptable, isFalse);
    });

    test('a revoked key throws instead of returning a verdict', () async {
      server.revoked = true;
      await expectLater(service.verify(_creds), throwsA(isA<KeyRevokedFailure>()));
    });

    test('the verification never calls anything that moves money', () async {
      await service.verify(_creds);
      final writes = server.requests.where((r) => r.method != 'GET').map((r) => '${r.method} ${r.uri.path}').toList();
      expect(writes, ['POST /api/1/stoporder', 'DELETE /api/1/withdrawals/0']);
    });
  });

  group('connect', () {
    test('creates the synced portfolio and connection, and stores the credentials only in the secure store', () async {
      final id = await connectOk(confirmed: true);
      final c = (await luno.getConnection(id))!;
      expect((c.label, c.homeFiat, c.keyIdHint, c.status, c.writePermWarning), ('Main', 'MYR', 'eyid', LunoConnectionStatus.ok, false));
      final p = (await portfolios.getPortfolios()).single;
      expect((p.id, p.name, p.costMethod), (c.portfolioId, 'Luno – Main', CostMethod.fifo));
      final stored = (await store.read(id))!;
      expect((stored.keyId, stored.keySecret), (_creds.keyId, _creds.keySecret));

      // Nothing about the secret reaches the database.
      final dump = StringBuffer();
      for (final t in db.allTables) {
        for (final r in await db.select(t).get()) {
          dump.write(r.toString());
        }
      }
      expect(dump.toString(), isNot(contains('SUPERSECRET')));
      expect(dump.toString(), isNot(contains('abcd1234keyid')));
    });

    test('without the attestation the connection keeps its send-permission warning', () async {
      final id = await connectOk();
      expect((await luno.getConnection(id))!.writePermWarning, isTrue);
    });

    test('a blank label becomes "Luno"', () async {
      expect((await luno.getConnection(await connectOk(label: '  ')))!.label, 'Luno');
    });

    test('refuses an unacceptable key without creating anything', () async {
      server.canStopOrders = true;
      final check = await service.verify(_creds);
      await expectLater(
        service.connect(credentials: _creds, check: check, label: 'x', homeFiat: 'MYR', costMethod: CostMethod.average),
        throwsA(isA<UnsafeKeyFailure>()),
      );
      expect(await portfolios.getPortfolios(), isEmpty);
      expect(await luno.getConnections(), isEmpty);
      expect(store.connectionIds, isEmpty);
    });

    test('refuses when the secure store is unavailable, and never falls back to anything else', () async {
      final check = await service.verify(_creds);
      store.available = false;
      await expectLater(
        service.connect(credentials: _creds, check: check, label: 'x', homeFiat: 'MYR', costMethod: CostMethod.average),
        throwsA(isA<SecureStorageUnavailableFailure>()),
      );
      expect(await portfolios.getPortfolios(), isEmpty);
      expect(await luno.getConnections(), isEmpty);
    });

    test('a failure while storing the key rolls back the portfolio and the connection', () async {
      final check = await service.verify(_creds);
      final failing = _FailingStore(store);
      final s = LunoConnectService(store: failing, luno: luno, portfolios: portfolios, dio: Dio()..httpClientAdapter = server.adapter);
      await expectLater(
        s.connect(credentials: _creds, check: check, label: 'x', homeFiat: 'MYR', costMethod: CostMethod.average),
        throwsA(isA<SecureStorageUnavailableFailure>()),
      );
      expect(await portfolios.getPortfolios(), isEmpty);
      expect(await luno.getConnections(), isEmpty);
      expect(store.connectionIds, isEmpty);
    });

    test('suggests the largest fiat wallet as the home currency', () {
      LunoAccount a(String asset, String total) =>
          LunoAccount(accountId: asset, asset: asset, balance: dec(total), reserved: dec(0), unconfirmed: dec(0));
      expect(LunoConnectService.suggestHomeFiat([a('XBT', '2'), a('ZAR', '10'), a('MYR', '500')]), 'MYR');
      expect(LunoConnectService.suggestHomeFiat([a('XBT', '2')], fallback: 'EUR'), 'EUR');
      expect(LunoConnectService.suggestHomeFiat([a('XBT', '2')], fallback: 'JPY'), 'USD');
    });
  });

  group('replaceKey', () {
    const other = LunoCredentials(keyId: 'newkeyid9999', keySecret: 'NEWSECRET-9876543210');

    test('stores the new key, updates the hint and clears a revoked status', () async {
      final id = await connectOk();
      await luno.setStatus(id, LunoConnectionStatus.revoked, error: 'revoked');
      await service.replaceKey(connectionId: id, credentials: other, check: await service.verify(other));
      final c = (await luno.getConnection(id))!;
      expect((c.status, c.keyIdHint, c.lastError), (LunoConnectionStatus.ok, '9999', null));
      expect((await store.read(id))!.keySecret, 'NEWSECRET-9876543210');
    });

    test('a key for a different Luno user is refused and the old key stays in place', () async {
      final id = await connectOk();
      await luno.upsertCursor(
        LunoAccountCursor(
          connectionId: id,
          accountId: 'someone-elses-account',
          asset: 'XBT',
          balanceSnapshot: dec(0),
          reservedSnapshot: dec(0),
          unconfirmedSnapshot: dec(0),
        ),
      );
      await expectLater(
        service.replaceKey(connectionId: id, credentials: other, check: await service.verify(other)),
        throwsA(isA<KeyMismatchFailure>()),
      );
      expect((await store.read(id))!.keyId, _creds.keyId);
    });

    test('an unacceptable replacement key is refused', () async {
      final id = await connectOk();
      server.canStopOrders = true;
      await expectLater(
        service.replaceKey(connectionId: id, credentials: other, check: await service.verify(other)),
        throwsA(isA<UnsafeKeyFailure>()),
      );
      expect((await store.read(id))!.keyId, _creds.keyId);
    });
  });

  group('disconnect', () {
    Future<(int, int)> withTransaction() async {
      final id = await connectOk();
      final conn = (await luno.getConnection(id))!;
      await luno.upsertSyncedTransactions(id, [
        PortfolioTransaction(
          id: 0,
          portfolioId: conn.portfolioId,
          symbol: 'LUNO:XBTMYR',
          type: TxType.buy,
          tradeDate: DateTime.utc(2024, 1, 2),
          quantity: dec(1),
          price: dec(100),
          fees: dec(0),
          currency: 'MYR',
          fxRateToBase: dec(1),
          createdAt: DateTime.utc(2024, 1, 3),
          source: TxSource.luno,
          connectionId: id,
          externalId: 'x',
          executedAt: DateTime.utc(2024, 1, 2),
        ),
      ]);
      return (id, conn.portfolioId);
    }

    test('keeping the portfolio wipes the key and leaves ordinary editable transactions', () async {
      final (id, pid) = await withTransaction();
      await service.disconnect(id, keepPortfolio: true);
      expect(await store.read(id), isNull);
      expect(await luno.getConnections(), isEmpty);
      final tx = (await portfolios.getTransactions()).single;
      expect((tx.portfolioId, tx.source, tx.connectionId, tx.externalId, tx.isSynced), (pid, TxSource.manual, null, null, false));
      expect(await portfolios.getPortfolios(), hasLength(1));
    });

    test('deleting removes the key, the portfolio and everything synced', () async {
      final (id, _) = await withTransaction();
      await service.disconnect(id, keepPortfolio: false);
      expect(await store.read(id), isNull);
      expect(await portfolios.getPortfolios(), isEmpty);
      expect(await portfolios.getTransactions(), isEmpty);
      expect(await luno.getConnections(), isEmpty);
    });

    test('if the secret cannot be removed nothing else changes, so the user can retry', () async {
      final (id, _) = await withTransaction();
      store.available = false;
      await expectLater(service.disconnect(id, keepPortfolio: false), throwsA(isA<SecureStorageUnavailableFailure>()));
      expect(await luno.getConnections(), hasLength(1));
      expect(await portfolios.getTransactions(), hasLength(1));
      store.available = true;
      await service.disconnect(id, keepPortfolio: false);
      expect(await store.read(id), isNull);
    });

    test('disconnectAll removes every connection and any stray secret', () async {
      await connectOk(label: 'A');
      await connectOk(label: 'B');
      await store.write(999, _creds); // a key whose connection no longer exists
      await service.disconnectAll(keepPortfolios: true);
      expect(await luno.getConnections(), isEmpty);
      expect(store.connectionIds, isEmpty);
      expect(await portfolios.getPortfolios(), hasLength(2));
    });
  });
}

/// Fails the write that stores the key, after the connection row exists.
class _FailingStore implements LunoCredentialStore {
  _FailingStore(this.inner);
  final FakeLunoCredentialStore inner;

  @override
  Future<LunoCredentials?> read(int connectionId) => inner.read(connectionId);
  @override
  Future<void> write(int connectionId, LunoCredentials credentials) async => throw const SecureStorageUnavailableFailure();
  @override
  Future<void> delete(int connectionId) => inner.delete(connectionId);
  @override
  Future<void> deleteAll() => inner.deleteAll();
  @override
  Future<bool> isAvailable() async => true;
}

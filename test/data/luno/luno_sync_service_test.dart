import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/core/failure.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/luno/luno_sync_service.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/domain/services/holdings_engine.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_luno_server.dart';
import '../../support/fake_market_data.dart';

Decimal d(String v) => Decimal.parse(v);

void main() {
  late AppDatabase db;
  late LunoRepositoryImpl luno;
  late PortfolioRepositoryImpl portfolios;
  late FakeLunoServer server;
  late FakeMarketData market;
  late FixedClock clock;
  late LunoSyncService service;
  late int pid;
  late int cid;

  LunoClient clientFor(FakeLunoServer s, {LunoCredentialSource? credentials}) => LunoClient(
    dio: Dio()..httpClientAdapter = s.adapter,
    credentials: credentials ?? () async => const LunoCredentials(keyId: 'k', keySecret: 's'),
    maxAttempts: 2,
    backoff: (_) async {},
    scheduler: RequestScheduler(),
  );

  LunoSyncService makeService({LunoCredentialSource? credentials, int pageSize = 1000}) => LunoSyncService(
    luno: luno,
    portfolios: portfolios,
    market: market,
    clientFor: (_) => clientFor(server, credentials: credentials),
    clock: clock,
    ledgerPageSize: pageSize,
  );

  Future<List<PortfolioTransaction>> txs() => luno.syncedTransactions(cid);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    luno = LunoRepositoryImpl(db);
    portfolios = PortfolioRepositoryImpl(db);
    server = FakeLunoServer();
    clock = FixedClock(DateTime.utc(2024, 6, 1, 12));
    market = FakeMarketData()
      ..daily['LUNO:XBTMYR'] = fakeCandles('2023-12-01', List.filled(250, 260000.0))
      ..daily['LUNO:ETHMYR'] = fakeCandles('2023-12-01', List.filled(250, 8000.0));
    pid = await portfolios.createPortfolio(const NewPortfolio(name: 'Luno'));
    cid = await luno.createConnection(label: 'Main', portfolioId: pid, keyIdHint: 'abcd', homeFiat: 'MYR', status: LunoConnectionStatus.ok);
    service = makeService();
  });
  tearDown(() => db.close());

  Future<LunoSyncResult> sync() => service.sync(cid, baseCurrency: 'MYR');

  group('first sync', () {
    test('stages the whole ledger, books every row, and replays exactly to the balances Luno reports', () async {
      final r = await sync();
      expect(r.ok, isTrue, reason: '${r.failure}');
      expect((r.rowsFetched, r.transactions, r.unrecognised, r.deferred), (15, 9, 0, 0));
      expect(r.mismatches, isEmpty);

      final c = (await luno.getConnection(cid))!;
      expect((c.status, c.lastError, c.unrecognisedRows), (LunoConnectionStatus.ok, null, 0));
      expect(c.lastSyncAt!.toUtc(), clock.value);

      final all = await txs();
      expect(all.length, 9);
      final replay = const HoldingsEngine().replay(all, CostMethod.average);
      expect(replay.cashBase, d('1598'));
      expect(replay.positions['LUNO:XBTMYR']!.quantity, d('0.01495'));
      expect(replay.positions['LUNO:ETHMYR']!.quantity, d('0.1'));

      // Every ledger row is staged as mapped, and every account's cursor sits on its last row with the balances recorded.
      expect((await luno.stagedRows(cid, states: {'mapped'})).length, 15);
      final cursors = await luno.getCursors(cid);
      expect(cursors['1002']!.lastRowIndex, 7);
      expect(cursors['1002']!.balanceSnapshot, d('0.01395'));
      expect(cursors['1002']!.reservedSnapshot, d('0.001'));
    });

    test('costs one balance call plus one ledger page per account', () async {
      await sync();
      expect(server.requests.where((r) => r.uri.path == '/api/1/balance').length, 1);
      expect(server.ledgerRequests.length, 3);
      expect(server.requests.length, 4);
    });

    test('registers an instrument for each Luno symbol so holdings show a name and an asset class', () async {
      await sync();
      final instruments = await portfolios.getInstruments();
      final btc = instruments['LUNO:XBTMYR']!;
      expect((btc.name, btc.quoteType, btc.exchange, btc.currency), ('Bitcoin', 'CRYPTOCURRENCY', 'Luno', 'MYR'));
      expect(instruments['LUNO:ETHMYR']!.name, 'Ethereum');
    });

    test('ledgers longer than one page are fetched page by page', () async {
      service = makeService(pageSize: 3);
      final r = await sync();
      expect(r.rowsFetched, 15);
      // 7 rows at 3 per page = pages of 3, 3 and 1 for MYR and XBT; ETH's single row is one short page.
      expect(server.ledgerRequests.length, 3 + 3 + 1);
      expect(server.ledgerRequests.where((q) => q.uri.path.contains('/1001/')).map((q) => q.queryParameters['min_row']), ['1', '4', '7']);
      expect(r.mismatches, isEmpty);
      expect((await txs()).length, 9);
    });
  });

  group('incremental sync', () {
    test('with nothing changed it costs a single call and books nothing new', () async {
      await sync();
      server.requests.clear();
      final r = await sync();
      expect(server.requests.length, 1);
      expect((r.ok, r.rowsFetched, r.transactions), (true, 0, 0));
      expect((await txs()).length, 9);
    });

    test('new activity in one account fetches only that account, from its cursor, and is booked once', () async {
      await sync();
      server.requests.clear();
      server.ledgers['1002']!.add({
        'row_index': 8,
        'timestamp': DateTime.utc(2024, 5, 20).millisecondsSinceEpoch,
        'balance': 0.0150,
        'available': 0.0150,
        'balance_delta': 0.00005,
        'available_delta': 0.00005,
        'currency': 'XBT',
        'kind': 'INTEREST',
        'reference': 'I-2',
        'description': 'Interest',
        'account_id': '1002',
      });
      server.setBalance('XBT', balance: '0.01400');
      final r = await sync();
      expect((r.rowsFetched, r.transactions), (1, 1));
      expect(server.ledgerRequests.map((q) => q.uri.path), ['/api/1/accounts/1002/transactions']);
      expect(server.ledgerRequests.single.queryParameters['min_row'], '8');
      expect((await txs()).length, 10);

      // Running it again changes nothing.
      server.requests.clear();
      await sync();
      expect(server.requests.length, 1);
      expect((await txs()).length, 10);
    });

    test('forgetting the cursors and syncing again duplicates nothing', () async {
      await sync();
      await db.delete(db.lunoAccountCursors).go();
      final r = await sync();
      expect(r.rowsFetched, 15);
      expect((await txs()).length, 9);
      expect((await luno.stagedRows(cid, states: {'mapped'})).length, 15);
    });
  });

  group('failures', () {
    test('an interrupted first sync resumes without refetching the accounts that completed', () async {
      server.failing['/api/1/accounts/1002/transactions'] = 503;
      final failed = await sync();
      expect(failed.failure, isA<NetworkFailure>());
      var c = (await luno.getConnection(cid))!;
      expect(c.status, LunoConnectionStatus.error);

      // MYR (fetched before the failure) is complete and recorded; XBT is not.
      final cursors = await luno.getCursors(cid);
      expect(cursors['1001']!.lastRowIndex, 7);
      expect(cursors.containsKey('1002'), isFalse);

      server.failing.clear();
      server.requests.clear();
      final r = await sync();
      expect(r.ok, isTrue);
      expect(server.ledgerRequests.map((q) => q.uri.path.split('/')[4]).toSet(), {'1002', '1003'}, reason: 'MYR was not fetched again');
      c = (await luno.getConnection(cid))!;
      expect(c.status, LunoConnectionStatus.ok);
      expect(r.mismatches, isEmpty);
      expect((await txs()).length, 9);
    });

    test('a revoked key marks the connection revoked and keeps everything already synced', () async {
      await sync();
      server.revoked = true;
      final r = await sync();
      expect(r.failure, isA<KeyRevokedFailure>());
      expect((await luno.getConnection(cid))!.status, LunoConnectionStatus.revoked);
      expect((await txs()).length, 9);

      // A revoked connection is not retried until the user replaces the key.
      server.requests.clear();
      final skipped = await sync();
      expect(skipped.skipped, isTrue);
      expect(server.requests, isEmpty);
    });

    test('missing credentials mark the connection credentials-missing before any request is made', () async {
      service = makeService(credentials: () async => throw const CredentialsMissingFailure());
      final r = await sync();
      expect(r.failure, isA<CredentialsMissingFailure>());
      expect((await luno.getConnection(cid))!.status, LunoConnectionStatus.credentialsMissing);
      expect(server.requests, isEmpty);
    });

    test('a rate-limited or unavailable API leaves the connection in error with its data intact', () async {
      await sync();
      server.balanceStatus = 503;
      final r = await sync();
      expect(r.failure, isA<NetworkFailure>());
      final c = (await luno.getConnection(cid))!;
      expect(c.status, LunoConnectionStatus.error);
      expect(c.lastError, isNotEmpty);
      expect((await txs()).length, 9);

      server.balanceStatus = null;
      expect((await sync()).ok, isTrue);
      expect((await luno.getConnection(cid))!.status, LunoConnectionStatus.ok);
    });

    test('a missing connection or one that cannot sync is skipped', () async {
      expect((await service.sync(9999, baseCurrency: 'MYR')).skipped, isTrue);
      await luno.setStatus(cid, LunoConnectionStatus.credentialsMissing);
      expect((await sync()).skipped, isTrue);
      expect(server.requests, isEmpty);
    });

    test('concurrent syncs of one connection share a single run', () async {
      final results = await Future.wait([sync(), sync()]);
      expect(results.first, same(results.last));
      expect(server.requests.length, 4);
    });

    test('cancelling stops between pages and leaves the connection resumable', () async {
      service = makeService(pageSize: 2);
      var calls = 0;
      final r = await service.sync(cid, baseCurrency: 'MYR', isCancelled: () => ++calls > 3);
      expect(r.ok, isFalse);
      final done = await sync();
      expect(done.ok, isTrue);
      expect((await txs()).length, 9);
    });
  });

  group('reconciliation', () {
    test('a balance that the ledger does not explain marks the connection needs-review and is never adjusted away', () async {
      server.setBalance('XBT', balance: '0.02');
      final r = await sync();
      expect(r.mismatches.single.asset, 'XBT');
      expect(r.mismatches.single.delta, d('-0.00605')); // synced 0.01495 vs Luno 0.021
      final c = (await luno.getConnection(cid))!;
      expect(c.status, LunoConnectionStatus.needsReview);
      expect(c.lastError, contains('XBT'));
      expect((await txs()).length, 9, reason: 'no balancing transaction was invented');
    });

    test('the mismatch clears by itself once the ledger catches up', () async {
      server.setBalance('XBT', balance: '0.02');
      await sync();
      server.ledgers['1002']!.add({
        'row_index': 8,
        'timestamp': DateTime.utc(2024, 5, 20).millisecondsSinceEpoch,
        'balance': 0.021,
        'available': 0.021,
        'balance_delta': 0.00605,
        'available_delta': 0.00605,
        'currency': 'XBT',
        'kind': 'TRANSFER',
        'reference': 'T-IN2',
        'description': 'Received',
        'account_id': '1002',
      });
      final r = await sync();
      expect(r.mismatches, isEmpty);
      expect((await luno.getConnection(cid))!.status, LunoConnectionStatus.ok);
    });
  });

  group('rows the mapper cannot place yet', () {
    LunoLedgerEntryJson leg(String account, String asset, num delta, {required String at}) => {
      'row_index': 1,
      'timestamp': DateTime.parse(at).millisecondsSinceEpoch,
      'balance': delta,
      'available': delta,
      'balance_delta': delta,
      'available_delta': delta,
      'currency': asset,
      'kind': 'EXCHANGE',
      'reference': 'NEW-1',
      'description': 'Trade',
      'account_id': account,
      'detail_fields': {
        'trade_details': {'pair': 'XBTMYR', 'price': '300000', 'volume': '0.001', 'sequence': 999},
      },
    };

    test('a trade leg whose counterpart has not been fetched yet is held back, then booked when it arrives', () async {
      await sync();
      final recent = clock.value.subtract(const Duration(minutes: 2)).toIso8601String();
      server.ledgers['1002']!.add({...leg('1002', 'XBT', 0.001, at: recent), 'row_index': 8});
      server.setBalance('XBT', balance: '0.01495'); // 0.01395 + 0.001 reserved + 0.001 new leg
      final waiting = await sync();
      expect((waiting.deferred, waiting.transactions), (1, 0));
      var c = (await luno.getConnection(cid))!;
      expect(c.status, LunoConnectionStatus.ok, reason: 'in-flight rows explain the difference');
      expect(c.lastError, contains('waiting'));
      expect((await txs()).length, 9);

      server.ledgers['1001']!.add({...leg('1001', 'MYR', -300, at: recent), 'row_index': 8});
      server.setBalance('MYR', balance: '1298.00');
      final done = await sync();
      expect((done.deferred, done.transactions), (0, 1));
      c = (await luno.getConnection(cid))!;
      expect((await txs()).length, 10);
      expect(c.lastError, isNull);
    });

    test('unrecognised rows are counted, kept for review, and never booked', () async {
      server.ledgers['1001']!.add({
        'row_index': 8,
        'timestamp': DateTime.utc(2024, 5, 21).millisecondsSinceEpoch,
        'balance': 1598,
        'available': 1598,
        'balance_delta': 5,
        'available_delta': 5,
        'currency': 'MYR',
        'kind': 'SOMETHING_NEW',
        'reference': 'Z',
        'description': 'New kind of entry',
        'account_id': '1001',
      });
      final r = await sync();
      expect(r.unrecognised, 1);
      expect((await luno.getConnection(cid))!.unrecognisedRows, 1);
      expect((await luno.stagedRows(cid, states: {'unrecognised'})).single.key, '1001:8');
      expect((await txs()).length, 9);
    });

    test('a price that was missing is picked up on a later sync', () async {
      market.daily.remove('LUNO:XBTMYR');
      final first = await sync();
      expect(first.deferred, 2, reason: 'the on-chain receive and the interest need a XBT price');
      expect(first.warnings.join(), contains('XBT'));
      expect((await txs()).any((t) => t.type == TxType.transferIn), isFalse);

      market.daily['LUNO:XBTMYR'] = fakeCandles('2023-12-01', List.filled(250, 260000.0));
      final second = await sync();
      expect(second.deferred, 0);
      expect((await txs()).length, 9);
      expect((await luno.getConnection(cid))!.status, LunoConnectionStatus.ok);
    });
  });

  test('remapAll rebuilds the same transactions from the staged rows without refetching anything', () async {
    await sync();
    final before = (await txs()).map((t) => '${t.externalId}|${t.type.dbName}|${t.quantity}|${t.price}').toSet();
    server.requests.clear();
    await service.remapAll(cid, baseCurrency: 'MYR');
    expect(server.requests, isEmpty);
    expect((await txs()).map((t) => '${t.externalId}|${t.type.dbName}|${t.quantity}|${t.price}').toSet(), before);
  });
}

typedef LunoLedgerEntryJson = Map<String, Object?>;

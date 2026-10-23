import 'dart:convert';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/backup/backup_service.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/luno/luno_client.dart';
import 'package:dashfolio/data/luno/luno_connect_service.dart';
import 'package:dashfolio/data/luno/luno_credential_store.dart';
import 'package:dashfolio/data/luno/luno_sync_service.dart';
import 'package:dashfolio/data/net/request_scheduler.dart';
import 'package:dashfolio/data/repositories/luno_repository_impl.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/data/repositories/settings_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/luno.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_luno_credentials.dart';
import '../../support/fake_luno_server.dart';
import '../../support/fake_market_data.dart';

const _creds = LunoCredentials(keyId: 'abcd1234keyid', keySecret: 'SUPERSECRET-0123456789');
const _newCreds = LunoCredentials(keyId: 'newkeyid5678', keySecret: 'OTHERSECRET-9876543210');

void main() {
  late AppDatabase db;
  late FakeLunoServer server;
  late FakeLunoCredentialStore store;
  late LunoRepositoryImpl luno;
  late PortfolioRepositoryImpl portfolios;
  late LunoConnectService connect;
  late LunoSyncService sync;
  late BackupService backup;
  late FixedClock clock;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = FakeLunoServer();
    store = FakeLunoCredentialStore();
    clock = FixedClock(DateTime.utc(2024, 6, 1, 12));
    luno = LunoRepositoryImpl(db);
    portfolios = PortfolioRepositoryImpl(db, clock);
    final dio = Dio()..httpClientAdapter = server.adapter;
    connect = LunoConnectService(store: store, luno: luno, portfolios: portfolios, dio: dio);
    final market = FakeMarketData()
      ..daily['LUNO:XBTMYR'] = fakeCandles('2023-12-01', List.filled(250, 260000.0))
      ..daily['LUNO:ETHMYR'] = fakeCandles('2023-12-01', List.filled(250, 8000.0));
    sync = LunoSyncService(
      luno: luno,
      portfolios: portfolios,
      market: market,
      clock: clock,
      clientFor: (_) => LunoClient(dio: dio, credentials: () async => _newCreds, scheduler: RequestScheduler(), backoff: (_) async {}),
    );
    backup = BackupService(portfolios, SettingsRepositoryImpl(db), clock, luno, store);
  });
  tearDown(() => db.close());

  Future<int> connectAndSync() async {
    final check = await connect.verify(_creds);
    final id = await connect.connect(credentials: _creds, check: check, label: 'Main', homeFiat: 'MYR', costMethod: CostMethod.average);
    final r = await sync.sync(id, baseCurrency: 'MYR');
    expect(r.ok, isTrue, reason: '${r.failure}');
    return id;
  }

  test('the backup carries connection metadata and synced transactions, and nothing that could unlock the account', () async {
    final id = await connectAndSync();
    final json = await backup.exportAll();
    final text = jsonEncode(json);

    final conns = (json['luno_connections']! as List).cast<Map<String, Object?>>();
    expect(conns.single['label'], 'Main');
    expect(conns.single['home_fiat'], 'MYR');
    expect(conns.single['key_id_hint'], 'eyid');
    expect(conns.single.keys.toSet(), {'id', 'label', 'portfolio_id', 'key_id_hint', 'home_fiat', 'write_perm_warning'});

    final txs = (json['transactions']! as List).cast<Map<String, Object?>>();
    expect(txs.length, 9);
    expect(
      txs.every((t) => t['source'] == 'luno' && t['connection_id'] == id && t['external_id'] != null && t['executed_at'] != null),
      isTrue,
    );

    expect(text, isNot(contains('SUPERSECRET')));
    expect(text, isNot(contains('abcd1234keyid')));
    expect(text, isNot(contains('OTHERSECRET')));
  });

  test('replace-restore brings the connection back without its key, wipes any stored keys, and keeps synced rows linked', () async {
    final id = await connectAndSync();
    final json = backup.parse(jsonEncode(await backup.exportAll()));
    expect(await store.read(id), isNotNull);

    final summary = await backup.restore(json, RestoreMode.replace);
    expect(summary.transactions, 9);
    expect(store.connectionIds, isEmpty, reason: 'keys do not survive a replace');

    final c = (await luno.getConnections()).single;
    expect((c.label, c.status, c.homeFiat, c.keyIdHint), ('Main', LunoConnectionStatus.credentialsMissing, 'MYR', 'eyid'));
    final txs = await luno.syncedTransactions(c.id);
    expect(txs.length, 9);
    expect(txs.every((t) => t.source == TxSource.luno && t.connectionId == c.id && t.executedAt != null), isTrue);
    expect((await portfolios.getPortfolios()).single.id, c.portfolioId);
  });

  test('a restored connection cannot sync until a key is entered; then syncing duplicates nothing and keeps notes', () async {
    await connectAndSync();
    final note = (await portfolios.getTransactions()).first;
    await portfolios.updateTransaction(note.copyWith(notes: 'my note'));
    final json = backup.parse(jsonEncode(await backup.exportAll()));
    await backup.restore(json, RestoreMode.replace);

    final c = (await luno.getConnections()).single;
    expect((await sync.sync(c.id, baseCurrency: 'MYR')).skipped, isTrue);

    final check = await connect.verify(_newCreds);
    await connect.replaceKey(connectionId: c.id, credentials: _newCreds, check: check);
    final r = await sync.sync(c.id, baseCurrency: 'MYR');
    expect(r.ok, isTrue, reason: '${r.failure}');
    expect(r.rowsFetched, 15, reason: 'the ledger is fetched again, because staged rows are not part of a backup');

    final txs = await luno.syncedTransactions(c.id);
    expect(txs.length, 9, reason: 'matched by external id, not duplicated');
    expect(txs.where((t) => t.notes == 'my note'), hasLength(1));
    expect((await luno.getConnection(c.id))!.status, LunoConnectionStatus.ok);
  });

  test('merge-restoring the same backup twice adds nothing', () async {
    await connectAndSync();
    final json = backup.parse(jsonEncode(await backup.exportAll()));
    final again = await backup.restore(json, RestoreMode.merge);
    expect(again.transactions, 0);
    expect(again.skipped, 9);
    expect(await luno.getConnections(), hasLength(1));
    expect((await portfolios.getTransactions()).length, 9);
  });

  test('a backup that lacks the connection turns its synced rows into ordinary transactions', () async {
    await connectAndSync();
    final json = backup.parse(jsonEncode(await backup.exportAll()));
    json.remove('luno_connections');
    await backup.restore(json, RestoreMode.replace);
    expect(await luno.getConnections(), isEmpty);
    final txs = await portfolios.getTransactions();
    expect(txs.length, 9);
    expect(txs.every((t) => t.source == TxSource.manual && t.connectionId == null && t.externalId == null), isTrue);
  });

  test('v1 backups, which know nothing about Luno, still restore', () async {
    final v1 = {
      'app': 'dashfolio',
      'schema_version': 1,
      'portfolios': [
        {'id': 1, 'name': 'Old', 'cost_basis_method': 'average'},
      ],
      'transactions': [
        {
          'portfolio_id': 1,
          'symbol': 'AAPL',
          'type': 'buy',
          'trade_date': '2024-01-02',
          'quantity': '1',
          'price': '10',
          'fees': '0',
          'currency': 'USD',
          'fx_rate_to_base': '1',
        },
      ],
    };
    final s = await backup.restore(backup.parse(jsonEncode(v1)), RestoreMode.replace);
    expect(s.transactions, 1);
    expect((await portfolios.getTransactions()).single.source, TxSource.manual);
  });

  test('restoring on a platform without Luno (no repository) keeps the data as plain portfolios', () async {
    await connectAndSync();
    final json = backup.parse(jsonEncode(await backup.exportAll()));
    final plain = BackupService(portfolios, SettingsRepositoryImpl(db), clock);
    await plain.restore(json, RestoreMode.replace);
    expect(await luno.getConnections(), isEmpty);
    expect((await portfolios.getTransactions()).every((t) => t.source == TxSource.manual), isTrue);
  });
}

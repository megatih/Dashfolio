import 'dart:convert';

import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/backup/backup_service.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/data/repositories/settings_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/domain/repositories/settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

void main() {
  late AppDatabase db;
  late PortfolioRepositoryImpl repo;
  late SettingsRepositoryImpl settings;
  late BackupService backup;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final clock = FixedClock(DateTime.utc(2024, 6, 1));
    repo = PortfolioRepositoryImpl(db, clock);
    settings = SettingsRepositoryImpl(db);
    backup = BackupService(repo, settings, clock);

    final a = await repo.createPortfolio(const NewPortfolio(name: 'Growth', costMethod: CostMethod.fifo, color: 0xFF10B981));
    final b = await repo.createPortfolio(const NewPortfolio(name: 'Income'));
    await repo.addTransactions([
      buy('AAPL', '2024-01-02', '10.5', '150.25', fees: '1.5', portfolio: a),
      sell('AAPL', '2024-03-01', 4, 180, portfolio: a),
      dividendTx('AAPL', '2024-02-15', '10.5', '0.24', portfolio: a),
      buy('SAP.DE', '2024-02-01', 3, 120, currency: 'EUR', fx: '1.0850', portfolio: b),
      tx(TxType.deposit, null, '2024-01-01', quantity: 1, price: 5000, portfolio: b),
    ]);
    final w = await repo.createWatchlist('Tech');
    await repo.addToWatchlist(w, 'NVDA');
    await repo.addToWatchlist(w, 'MSFT');
    await repo.upsertInstrument(const Instrument(symbol: 'AAPL', name: 'Apple Inc.', quoteType: 'EQUITY', exchange: 'NasdaqGS'));
    await settings.set(SettingKeys.baseCurrency, 'EUR');
    await settings.set(SettingKeys.lockEnabled, 'true');
  });
  tearDown(() => db.close());

  Future<List<String>> txSignatures() async => [
    for (final t in await repo.watchTransactions().first)
      '${t.symbol}|${t.type.dbName}|${t.tradeDate.toIso8601String()}|${t.quantity}|${t.price}|${t.fees}|${t.currency}|${t.fxRateToBase}',
  ]..sort();

  test('export contains versioned data and omits lock settings', () async {
    final json = await backup.exportAll();
    expect(json['schema_version'], 2);
    expect(json['app'], 'dashfolio');
    expect((json['portfolios']! as List).length, 2);
    expect((json['transactions']! as List).length, 5);
    final s = json['settings']! as Map;
    expect(s[SettingKeys.baseCurrency], 'EUR');
    expect(s.containsKey(SettingKeys.lockEnabled), isFalse);
  });

  test('backup -> wipe -> restore (replace) reproduces identical data', () async {
    final before = await txSignatures();
    final text = await backup.exportJson();

    await repo.wipeUserData();
    await settings.remove(SettingKeys.baseCurrency);
    expect(await repo.watchTransactions().first, isEmpty);

    final summary = await backup.restore(backup.parse(text), RestoreMode.replace);
    expect(summary.portfolios, 2);
    expect(summary.transactions, 5);
    expect(summary.skipped, 0);
    expect(await txSignatures(), before);

    final portfolios = await repo.watchPortfolios().first;
    expect(portfolios.map((p) => p.name), ['Growth', 'Income']);
    expect(portfolios.first.costMethod, CostMethod.fifo);
    expect(portfolios.first.color, 0xFF10B981);
    expect((await repo.watchWatchlists().first).single.symbols, ['NVDA', 'MSFT']);
    expect(await settings.get(SettingKeys.baseCurrency), 'EUR');
    expect((await repo.watchInstruments().first)['AAPL']!.name, 'Apple Inc.');
  });

  test('merge skips existing portfolios and duplicate transactions', () async {
    final json = backup.parse(await backup.exportJson());
    final summary = await backup.restore(json, RestoreMode.merge);
    expect(summary.portfolios, 0);
    expect(summary.transactions, 0);
    expect(summary.skipped, 5);
    expect((await repo.watchTransactions().first).length, 5);
    expect((await repo.watchWatchlists().first).single.symbols, ['NVDA', 'MSFT']);
  });

  test('merge adds new data from another backup', () async {
    final json = backup.parse(await backup.exportJson());
    (json['portfolios']! as List).add({'id': 99, 'name': 'Crypto', 'cost_basis_method': 'average', 'color': 0xFF8B5CF6, 'archived': false});
    (json['transactions']! as List).add({
      'portfolio_id': 99,
      'symbol': 'BTC-USD',
      'type': 'buy',
      'trade_date': '2024-04-01',
      'quantity': '0.5',
      'price': '60000',
      'fees': '0',
      'currency': 'USD',
      'fx_rate_to_base': '1',
    });
    (json['watchlists']! as List).add({
      'name': 'Tech',
      'symbols': ['NVDA', 'AMD'],
    });
    final summary = await backup.restore(json, RestoreMode.merge);
    expect(summary.portfolios, 1);
    expect(summary.transactions, 1);
    expect((await repo.watchPortfolios().first).map((p) => p.name), contains('Crypto'));
    expect((await repo.watchWatchlists().first).single.symbols, ['NVDA', 'MSFT', 'AMD']);
  });

  test('malformed transactions are skipped, not fatal', () async {
    final json = backup.parse(await backup.exportJson());
    final txs = json['transactions']! as List;
    txs.add({'portfolio_id': 1, 'type': 'buy', 'trade_date': 'nope', 'quantity': '1', 'price': '1'});
    txs.add('garbage');
    txs.add({'portfolio_id': 12345, 'type': 'buy', 'trade_date': '2024-01-01', 'quantity': '1', 'price': '1'});
    await repo.wipeUserData();
    final summary = await backup.restore(json, RestoreMode.replace);
    expect(summary.transactions, 5);
    expect(summary.skipped, 3);
  });

  group('parse validation', () {
    test('rejects non-JSON, foreign files and newer schemas', () {
      expect(() => backup.parse('not json'), throwsA(isA<BackupFormatException>()));
      expect(() => backup.parse('{"hello": 1}'), throwsA(isA<BackupFormatException>()));
      expect(() => backup.parse('[]'), throwsA(isA<BackupFormatException>()));
      expect(
        () => backup.parse(jsonEncode({'app': 'dashfolio', 'schema_version': 99, 'portfolios': <Object>[], 'transactions': <Object>[]})),
        throwsA(predicate((e) => '$e'.contains('newer version'))),
      );
      expect(() => backup.parse(jsonEncode({'app': 'dashfolio', 'schema_version': 1})), throwsA(isA<BackupFormatException>()));
    });

    test('preview reports counts', () async {
      final p = backup.preview(backup.parse(await backup.exportJson()));
      expect((p.portfolios, p.transactions, p.watchlists, p.schemaVersion), (2, 5, 1, 2));
      expect(p.exportedAt, DateTime.utc(2024, 6, 1));
    });
  });

  test('transactions CSV has a header, portfolio names and exact decimals', () async {
    final csvText = await backup.exportTransactionsCsv();
    final lines = csvText.trim().split('\n');
    expect(lines.first, 'date,portfolio,type,symbol,quantity,price,fees,currency,fx_rate_to_base,notes');
    expect(lines.length, 6);
    expect(csvText, contains('2024-01-02,Growth,buy,AAPL,10.5,150.25,1.5,USD,1,'));
    expect(csvText, contains('SAP.DE,3,120,0,EUR,1.085'));
  });
}

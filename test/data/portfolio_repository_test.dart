import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/data/repositories/settings_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

void main() {
  late AppDatabase db;
  late PortfolioRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PortfolioRepositoryImpl(db, FixedClock(DateTime.utc(2024, 1, 1)));
  });
  tearDown(() => db.close());

  test('creates portfolios with increasing sort order and persists cost method', () async {
    final a = await repo.createPortfolio(const NewPortfolio(name: ' Growth '));
    final b = await repo.createPortfolio(const NewPortfolio(name: 'Income', costMethod: CostMethod.fifo));
    final list = await repo.watchPortfolios().first;
    expect(list.map((p) => p.name), ['Growth', 'Income']);
    expect(list.map((p) => p.id), [a, b]);
    expect(list.last.costMethod, CostMethod.fifo);

    await repo.reorderPortfolios([b, a]);
    expect((await repo.watchPortfolios().first).map((p) => p.name), ['Income', 'Growth']);
  });

  test('transactions round-trip decimals and dates exactly and cascade on portfolio delete', () async {
    final p = await repo.createPortfolio(const NewPortfolio(name: 'P'));
    final t = buy('AAPL', '2024-03-05', '10.123456789', '123.456789', fees: '1.5', portfolio: p);
    final id = await repo.addTransaction(t);

    var txs = await repo.watchTransactions().first;
    expect(txs.single.id, id);
    expect(txs.single.quantity, D('10.123456789'));
    expect(txs.single.price, D('123.456789'));
    expect(txs.single.tradeDate, DateTime.utc(2024, 3, 5));
    expect(txs.single.type, TxType.buy);

    await repo.updateTransaction(txs.single.copyWith(fxRateToBase: D('1.25')));
    txs = await repo.watchTransactions().first;
    expect(txs.single.fxRateToBase, D('1.25'));

    await repo.deletePortfolio(p);
    expect(await repo.watchTransactions().first, isEmpty);
  });

  test('opening_position type persists with its snake_case name', () async {
    final p = await repo.createPortfolio(const NewPortfolio(name: 'P'));
    await repo.addTransaction(tx(TxType.openingPosition, 'X', '2024-01-02', quantity: 5, price: 10, portfolio: p));
    final row = await db.select(db.transactions).getSingle();
    expect(row.type, 'opening_position');
    expect((await repo.watchTransactions().first).single.type, TxType.openingPosition);
  });

  test('import batches can be undone as a unit', () async {
    final p = await repo.createPortfolio(const NewPortfolio(name: 'P'));
    PortfolioTransaction withBatch(PortfolioTransaction t) => PortfolioTransaction(
      id: 0,
      portfolioId: p,
      symbol: t.symbol,
      type: t.type,
      tradeDate: t.tradeDate,
      quantity: t.quantity,
      price: t.price,
      fees: t.fees,
      currency: t.currency,
      fxRateToBase: t.fxRateToBase,
      importBatchId: 'batch-1',
      createdAt: t.createdAt,
    );
    await repo.addTransaction(buy('KEEP', '2024-01-02', 1, 1, portfolio: p));
    await repo.addTransactions([withBatch(buy('A', '2024-01-03', 1, 1)), withBatch(buy('B', '2024-01-04', 1, 1))]);
    expect((await repo.watchTransactions().first).length, 3);
    expect(await repo.deleteImportBatch('batch-1'), 2);
    expect((await repo.watchTransactions().first).single.symbol, 'KEEP');
  });

  test('watchlists keep item order and ignore duplicates', () async {
    final w = await repo.createWatchlist('Tech');
    await repo.addToWatchlist(w, 'AAPL');
    await repo.addToWatchlist(w, 'MSFT');
    await repo.addToWatchlist(w, 'AAPL');
    await repo.addToWatchlist(w, 'NVDA');
    expect((await repo.watchWatchlists().first).single.symbols, ['AAPL', 'MSFT', 'NVDA']);

    await repo.reorderWatchlistItems(w, ['NVDA', 'AAPL', 'MSFT']);
    expect((await repo.watchWatchlists().first).single.symbols, ['NVDA', 'AAPL', 'MSFT']);

    await repo.removeFromWatchlist(w, 'AAPL');
    await repo.renameWatchlist(w, 'Mega caps');
    final l = (await repo.watchWatchlists().first).single;
    expect(l.name, 'Mega caps');
    expect(l.symbols, ['NVDA', 'MSFT']);
  });

  test('wipeUserData clears everything user-owned', () async {
    final p = await repo.createPortfolio(const NewPortfolio(name: 'P'));
    await repo.addTransaction(buy('A', '2024-01-02', 1, 1, portfolio: p));
    final w = await repo.createWatchlist('W');
    await repo.addToWatchlist(w, 'A');
    await repo.saveImportMapping('broker', {'date': 'Trade Date'});
    await repo.wipeUserData();
    expect(await repo.watchPortfolios().first, isEmpty);
    expect(await repo.watchTransactions().first, isEmpty);
    expect(await repo.watchWatchlists().first, isEmpty);
    expect(await repo.watchImportMappings().first, isEmpty);
  });

  test('import mappings upsert by name', () async {
    await repo.saveImportMapping('m', {'a': 'x'});
    await repo.saveImportMapping('m', {'a': 'y'});
    final list = await repo.watchImportMappings().first;
    expect(list.length, 1);
    expect(list.single.mapping['a'], 'y');
  });

  test('settings repository set/get/remove', () async {
    final s = SettingsRepositoryImpl(db);
    expect(await s.get('k'), isNull);
    await s.set('k', 'v1');
    await s.set('k', 'v2');
    expect(await s.get('k'), 'v2');
    expect((await s.watchAll().first)['k'], 'v2');
    await s.remove('k');
    expect(await s.get('k'), isNull);
  });
}

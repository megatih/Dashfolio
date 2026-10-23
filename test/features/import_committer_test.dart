import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/domain/services/csv_import.dart';
import 'package:dashfolio/domain/services/fx.dart';
import 'package:dashfolio/features/import_export/import_committer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fake_market_data.dart';

void main() {
  late AppDatabase db;
  late PortfolioRepositoryImpl repo;
  late FakeMarketData market;
  late ImportCommitter committer;
  late int pid;
  const imp = CsvImporter();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final clock = FixedClock(DateTime.utc(2024, 6, 1, 12));
    repo = PortfolioRepositoryImpl(db, clock);
    market = FakeMarketData();
    committer = ImportCommitter(portfolios: repo, market: market, clock: clock);
    pid = await repo.createPortfolio(const NewPortfolio(name: 'Broker'));
  });
  tearDown(() => db.close());

  List<ImportRow> rows(String csvText, {ImportOptions options = const ImportOptions()}) {
    final r = parseCsvText(csvText);
    return imp.parse(rows: r, mapping: imp.autoDetect(r.first), options: options, today: DateTime.utc(2024, 6, 1));
  }

  test('imports valid rows in one batch, skipping invalid ones', () async {
    market.setQuote(fakeQuote('AAPL', name: 'Apple Inc.'));
    final parsed = rows(
      'Date,Symbol,Action,Qty,Price,Fees\n2024-01-02,AAPL,Buy,10,150,1\n2024-01-03,AAPL,Wire,1,1,0\n2024-02-01,AAPL,Sell,4,160,0\n',
    );
    final result = await committer.commit(
      portfolioId: pid,
      rows: parsed,
      baseCurrency: 'USD',
      knownQuotes: market.quotes,
      currentFx: const IdentityFx(),
    );
    expect(result.imported, 2);
    final txs = await repo.watchTransactions().first;
    expect(txs.length, 2);
    expect(txs.every((t) => t.importBatchId == result.batchId), isTrue);
    expect(txs.every((t) => t.currency == 'USD' && t.fxRateToBase == D('1')), isTrue);
    expect((await repo.watchInstruments().first)['AAPL']!.name, 'Apple Inc.');
    expect(market.refreshCalls.last, contains('AAPL'));
  });

  test('undoing the batch removes exactly the imported rows', () async {
    await repo.addTransaction(buy('KEEP', '2024-01-01', 1, 1, portfolio: pid));
    market.setQuote(fakeQuote('AAPL'));
    final result = await committer.commit(
      portfolioId: pid,
      rows: rows('Date,Symbol,Action,Qty,Price\n2024-01-02,AAPL,Buy,1,1\n2024-01-03,AAPL,Buy,2,2\n'),
      baseCurrency: 'USD',
      knownQuotes: market.quotes,
      currentFx: const IdentityFx(),
    );
    expect(await repo.deleteImportBatch(result.batchId), 2);
    expect((await repo.watchTransactions().first).single.symbol, 'KEEP');
  });

  test('uses historical FX for foreign currencies and flags fallbacks', () async {
    market.setQuote(fakeQuote('SAP.DE', currency: 'EUR'));
    market.daily['EURUSD=X'] = fakeCandles('2024-01-01', [1.10, 1.11, 1.12, 1.13, 1.14]);
    final parsed = rows('Date,Symbol,Action,Qty,Price\n2024-01-03,SAP.DE,Buy,5,120\n2023-12-20,SAP.DE,Buy,1,100\n');
    final result = await committer.commit(
      portfolioId: pid,
      rows: parsed,
      baseCurrency: 'USD',
      knownQuotes: market.quotes,
      currentFx: QuoteFxRates({'EURUSD=X': 1.2}),
    );
    final byDate = {for (final t in await repo.watchTransactions().first) t.tradeDate: t};
    expect(byDate[DateTime.utc(2024, 1, 3)]!.fxRateToBase, D('1.12'));
    expect(byDate[DateTime.utc(2024, 1, 3)]!.currency, 'EUR');
    // Before the first FX observation the series falls back to its first rate (no extrapolation to "now").
    expect(byDate[DateTime.utc(2023, 12, 20)]!.fxRateToBase, D('1.1'));
    expect(result.fxFallbacks, 0);
  });

  test('falls back to the current rate when no FX history exists', () async {
    market.setQuote(fakeQuote('SAP.DE', currency: 'EUR'));
    final result = await committer.commit(
      portfolioId: pid,
      rows: rows('Date,Symbol,Action,Qty,Price\n2024-01-03,SAP.DE,Buy,5,120\n'),
      baseCurrency: 'USD',
      knownQuotes: market.quotes,
      currentFx: QuoteFxRates({'EURUSD=X': 1.2}),
    );
    expect(result.fxFallbacks, 1);
    expect((await repo.watchTransactions().first).single.fxRateToBase, D('1.2'));
  });

  test('cash rows are stored in the base currency without a symbol', () async {
    final result = await committer.commit(
      portfolioId: pid,
      rows: rows('Date,Action,Amount\n2024-01-02,Deposit,2500\n'),
      baseCurrency: 'EUR',
      knownQuotes: const {},
      currentFx: const IdentityFx(),
    );
    expect(result.imported, 1);
    final t = (await repo.watchTransactions().first).single;
    expect(t.symbol, isNull);
    expect(t.type, TxType.deposit);
    expect(t.currency, 'EUR');
    expect(t.price, D('2500'));
  });

  test('row currency overrides the quote and unknown symbols use the default', () async {
    final result = await committer.commit(
      portfolioId: pid,
      rows: rows('Date,Symbol,Action,Qty,Price,Currency\n2024-01-02,XYZ,Buy,1,10,CAD\n2024-01-03,ABC,Buy,1,10,\n'),
      baseCurrency: 'USD',
      knownQuotes: const {},
      currentFx: QuoteFxRates({'CADUSD=X': 0.74}),
      defaultCurrency: 'USD',
    );
    final txs = {for (final t in await repo.watchTransactions().first) t.symbol: t};
    expect(txs['XYZ']!.currency, 'CAD');
    expect(txs['ABC']!.currency, 'USD');
    expect(result.currencyFallbacks, 1);
  });
}

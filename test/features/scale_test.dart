import 'package:dashfolio/core/clock.dart';
import 'package:dashfolio/data/db/app_database.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dashfolio/domain/entities/portfolio.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/domain/services/allocation.dart';
import 'package:dashfolio/domain/services/csv_import.dart';
import 'package:dashfolio/domain/services/fx.dart';
import 'package:dashfolio/domain/services/holdings_engine.dart';
import 'package:dashfolio/domain/services/valuation.dart';
import 'package:dashfolio/domain/services/value_history.dart';
import 'package:dashfolio/features/import_export/import_committer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fake_market_data.dart';

/// Acceptance-criteria checks: large imports and large portfolios stay fast and correct.
void main() {
  group('CSV import at scale', () {
    final today = DateTime.utc(2024, 6, 1);
    const imp = CsvImporter();

    String bigCsv(int rows) {
      final b = StringBuffer('Date,Symbol,Action,Qty,Price,Fees\n');
      for (var i = 0; i < rows; i++) {
        final day = DateTime.utc(2023, 1, 1).add(Duration(days: i % 400));
        final sym = 'SYM${i % 120}';
        // Every 7th row is bad on purpose.
        final action = i % 7 == 6 ? 'Nonsense' : (i % 5 == 4 ? 'Sell' : 'Buy');
        b.writeln('${day.toIso8601String().substring(0, 10)},$sym,$action,${1 + i % 9},${(10 + i % 50) / 4},0.5');
      }
      return b.toString();
    }

    test('1,200 rows parse, validate and flag errors quickly', () {
      final sw = Stopwatch()..start();
      final rows = parseCsvText(bigCsv(1200));
      expect(rows.length, 1201);
      final parsed = imp.parse(rows: rows, mapping: imp.autoDetect(rows.first), today: today);
      final marked = imp.markDuplicates(parsed, const []);
      sw.stop();
      expect(parsed.length, 1200);
      expect(marked.where((r) => !r.valid).length, greaterThan(150));
      expect(marked.where((r) => r.valid).length, greaterThan(900));
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('1,200 rows commit as one undoable batch', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final clock = FixedClock(DateTime.utc(2024, 6, 1, 12));
      final repo = PortfolioRepositoryImpl(db, clock);
      final pid = await repo.createPortfolio(const NewPortfolio(name: 'Big'));
      final market = FakeMarketData();
      for (var s = 0; s < 120; s++) {
        market.setQuote(fakeQuote('SYM$s'));
      }
      final rows = parseCsvText(bigCsv(1200));
      final parsed = imp.parse(rows: rows, mapping: imp.autoDetect(rows.first), today: today);
      final valid = parsed.where((r) => r.valid).toList();

      final result = await ImportCommitter(
        portfolios: repo,
        market: market,
        clock: clock,
      ).commit(portfolioId: pid, rows: parsed, baseCurrency: 'USD', knownQuotes: market.quotes, currentFx: const IdentityFx());
      expect(result.imported, valid.length);
      expect((await repo.getTransactions()).length, valid.length);
      expect(await repo.deleteImportBatch(result.batchId), valid.length);
      expect(await repo.getTransactions(), isEmpty);
    });
  });

  group('large portfolios', () {
    test('5 portfolios / 500 holdings / 5,000 transactions replay, value and group within a second or two', () {
      final txs = <PortfolioTransaction>[];
      for (var p = 0; p < 5; p++) {
        for (var s = 0; s < 100; s++) {
          final sym = 'S${p * 100 + s}';
          for (var t = 0; t < 10; t++) {
            txs.add(
              t == 9
                  ? sell(sym, '2023-12-${10 + t}', 1, 12 + t, portfolio: p + 1)
                  : buy(sym, '2023-0${1 + t % 9}-1${t % 9}', 3, 10 + t, portfolio: p + 1),
            );
          }
        }
      }
      expect(txs.length, 5000);
      final quotes = {
        for (var i = 0; i < 500; i++)
          'S$i': Quote(
            symbol: 'S$i',
            price: 20 + i % 30.0,
            previousClose: 19,
            currency: 'USD',
            quoteType: 'EQUITY',
            sector: 'Sector ${i % 11}',
            fetchedAt: DateTime.utc(2024),
          ),
      };

      final sw = Stopwatch()..start();
      const engine = HoldingsEngine();
      const valuation = Valuation();
      final parts = <ValuedPortfolio>[];
      for (var p = 1; p <= 5; p++) {
        final positions = engine.replay(txs.where((t) => t.portfolioId == p), p.isEven ? CostMethod.fifo : CostMethod.average);
        parts.add(valuation.value(positions, quotes, const IdentityFx(), 'USD'));
      }
      final merged = valuation.merge(parts.map((p) => p.holdings));
      final slices = const Allocation().group(merged, AllocationGroup.sector);
      sw.stop();

      expect(merged.length, 500);
      expect(slices.length, 11);
      expect(sw.elapsedMilliseconds, lessThan(4000));
    });

    test('value history over 5 years for 500 symbols stays well under a few seconds', () {
      final txs = [for (var s = 0; s < 500; s++) buy('S$s', '2019-06-${(1 + s % 28).toString().padLeft(2, '0')}', 2, 10)];
      final dates = [for (var i = 0; i < 1900; i++) DateTime.utc(2019, 1, 1).add(Duration(days: i))];
      final prices = {
        for (var s = 0; s < 500; s++) 'S$s': PriceSeries(dates, [for (var i = 0; i < dates.length; i++) 10 + (i % 17) * 0.5]),
      };

      final sw = Stopwatch()..start();
      final r = const ValueHistory().compute(
        transactions: txs,
        prices: prices,
        symbolCurrency: {for (var s = 0; s < 500; s++) 'S$s': 'USD'},
        fxToBase: const {},
        base: 'USD',
        range: HistoryRange.max,
        now: DateTime.utc(2024, 3, 1),
      );
      sw.stop();
      expect(r.points.length, lessThanOrEqualTo(602));
      expect(r.points.last.value, greaterThan(0));
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });
  });
}

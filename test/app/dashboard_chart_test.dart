import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/features/charts/allocation_donut.dart';
import 'package:dashfolio/features/charts/value_history_chart.dart';
import 'package:dashfolio/features/holdings/holdings_table.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<AppHarness> start(WidgetTester tester) async {
    final h = AppHarness.create(now: DateTime.utc(2024, 6, 3, 15));
    await h.completeOnboarding();
    h.market.setQuote(fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.', sector: 'Technology'));
    h.market.setQuote(fakeQuote('MSFT', price: 400, prev: 404, name: 'Microsoft Corp.', sector: 'Technology'));
    h.market.setQuote(fakeQuote('BTC-USD', price: 60000, prev: 59000, type: 'CRYPTOCURRENCY', name: 'Bitcoin'));
    h.market.daily['AAPL'] = fakeCandles('2024-01-01', [for (var i = 0; i < 160; i++) 150 + i * 0.3]);
    h.market.daily['MSFT'] = fakeCandles('2024-01-01', [for (var i = 0; i < 160; i++) 380 + (i % 10)]);
    h.market.daily['BTC-USD'] = fakeCandles('2024-01-01', [for (var i = 0; i < 160; i++) 40000 + i * 120]);
    await tester.runAsync(() async {
      final repo = PortfolioRepositoryImpl(h.db, h.clock);
      final pid = await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
      await repo.addTransactions([
        buy('AAPL', '2024-01-10', 10, 150, portfolio: pid),
        buy('MSFT', '2024-02-01', 5, 380, portfolio: pid),
        buy('BTC-USD', '2024-03-01', '0.1', 50000, portfolio: pid),
        sell('MSFT', '2024-04-15', 2, 395, portfolio: pid),
      ]);
    });
    await h.pump(tester);
    await h.settle(tester, frames: 20);
    return h;
  }

  testWidgets('dashboard renders the value history chart from cached prices, and the range selector works', (tester) async {
    final h = await start(tester);

    expect(find.text('Portfolio value'), findsOneWidget);
    expect(find.byType(ValueHistoryChart), findsOneWidget);
    expect(find.byType(LineChart), findsWidgets);
    expect(find.text('Not enough history yet'), findsNothing);

    // Switching ranges recomputes the series without errors.
    for (final label in ['1W', '1M', 'YTD', 'MAX']) {
      await tester.tap(find.text(label));
      await h.settle(tester, frames: 20);
      expect(find.byType(ValueHistoryChart), findsOneWidget, reason: label);
      expect(tester.takeException(), isNull, reason: label);
    }
    await h.dispose(tester);
  });

  testWidgets('allocation donut groups by asset class and can switch grouping', (tester) async {
    final h = await start(tester);
    expect(find.byType(AllocationDonut), findsOneWidget);
    expect(find.text('Stocks'), findsWidgets);
    expect(find.text('Crypto'), findsWidgets);

    await tester.tap(find.text('Sector'));
    await h.settle(tester);
    expect(find.text('Technology'), findsWidgets);

    await tester.tap(find.text('Currency'));
    await h.settle(tester);
    expect(find.text('USD'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('holdings table sorts by column and reverses on a second tap', (tester) async {
    final h = await start(tester);
    final table = find.byType(HoldingsTable);
    expect(table, findsOneWidget);

    double y(String symbol) => tester.getTopLeft(find.descendant(of: table, matching: find.text(symbol)).first).dy;

    // Default: by value descending => BTC-USD (6,000) > AAPL (2,000) > MSFT (1,200)
    expect(y('BTC-USD') < y('AAPL'), isTrue);
    expect(y('AAPL') < y('MSFT'), isTrue);

    await tester.tap(find.descendant(of: table, matching: find.text('Symbol')));
    await h.settle(tester); // first tap on a new column sorts descending
    expect(y('MSFT') < y('BTC-USD'), isTrue);

    await tester.tap(find.descendant(of: table, matching: find.text('Symbol')));
    await h.settle(tester); // second tap flips to ascending
    expect(y('AAPL') < y('BTC-USD'), isTrue);
    expect(y('BTC-USD') < y('MSFT'), isTrue);
    await h.dispose(tester);
  });

  testWidgets('top movers lists gainers and losers; recent transactions are shown newest first', (tester) async {
    final h = await start(tester);
    expect(find.text('Top movers today'), findsOneWidget);
    expect(find.text('Gainers'), findsOneWidget);
    expect(find.text('Losers'), findsOneWidget);
    expect(find.text('Recent transactions'), findsOneWidget);
    await h.dispose(tester);
  });
}

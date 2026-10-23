import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/finders.dart';
import '../support/builders.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

Finder field(String label) =>
    find.descendant(of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label), matching: find.byType(EditableText));

void main() {
  setUpAll(loadAppFonts);
  for (final skin in AppSkin.values) {
    group(skin.name, () {
      Future<AppHarness> startWithPortfolio(WidgetTester tester, {List<dynamic> txs = const []}) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        h.market.setQuote(fakeQuote('AAPL', price: 100, prev: 100, name: 'Apple Inc.'));
        h.market.searchResponse = const SearchResponse(
          results: [SearchResult(symbol: 'AAPL', name: 'Apple Inc.', quoteType: 'EQUITY', exchange: 'NASDAQ')],
          news: [],
        );
        await tester.runAsync(() async {
          final repo = PortfolioRepositoryImpl(h.db, h.clock);
          await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
        });
        await h.pump(tester);
        return h;
      }

      Future<void> openForm(WidgetTester tester, AppHarness h) async {
        await tester.tap(byAction('Add transaction (Ctrl/Cmd+N)').first);
        await h.settle(tester);
        expect(find.text('Add transaction'), findsWidgets);
      }

      testWidgets('add a buy: search symbol, fill the form, see it valued on the dashboard', (tester) async {
        final h = await startWithPortfolio(tester);
        expect(find.text('Add your first transaction'), findsOneWidget);

        await openForm(tester, h);
        await tester.enterText(find.descendant(of: anyDialog(), matching: find.byType(EditableText)).first, 'aapl');
        await tester.pump(const Duration(milliseconds: 400)); // debounce
        await h.settle(tester, frames: 4);
        await tester.tap(find.text('Apple Inc.').last);
        await h.settle(tester);

        await tester.enterText(field('Quantity'), '5');
        await tester.enterText(field('Price per share (USD)'), '80');
        await tester.pump();
        expect(find.textContaining(r'$400.00'), findsWidgets); // live total preview

        await tester.tap(byConfirm('Add transaction').last);
        await h.settle(tester, frames: 20);

        final txs = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).watchTransactions().first))!;
        expect(txs.single.symbol, 'AAPL');
        expect(txs.single.type, TxType.buy);
        expect(txs.single.quantity, D('5'));
        expect(txs.single.price, D('80'));
        expect(h.market.refreshCalls.any((s) => s.contains('AAPL')), isTrue); // prices requested for the new holding

        // 5 shares * $100 = $500 value; cost $400 => +$100 unrealized
        expect(find.text(r'$500.00'), findsWidgets);
        expect(find.text('Add your first transaction'), findsNothing);
        await h.dispose(tester);
      });

      testWidgets('validation: empty fields and overselling are reported without saving', (tester) async {
        final h = await startWithPortfolio(tester);
        await tester.runAsync(() async {
          final repo = PortfolioRepositoryImpl(h.db, h.clock);
          final pid = (await repo.watchPortfolios().first).single.id;
          await repo.addTransaction(buy('AAPL', '2024-01-02', 3, 50, portfolio: pid));
        });
        await h.settle(tester);

        await openForm(tester, h);
        await tester.tap(byConfirm('Add transaction').last); // submit empty
        await h.settle(tester);
        expect(find.text('Choose a symbol'), findsOneWidget);
        expect(find.text('Please fix the highlighted fields.'), findsOneWidget);

        // Switch to Sell, pick the symbol and try to sell more than held.
        await tester.tap(find.text('Buy').last);
        await h.settle(tester);
        await tester.tap(find.text('Sell').last);
        await h.settle(tester);
        await tester.enterText(find.descendant(of: anyDialog(), matching: find.byType(EditableText)).first, 'aapl');
        await tester.pump(const Duration(milliseconds: 400));
        await h.settle(tester, frames: 4);
        await tester.tap(find.text('Apple Inc.').last);
        await h.settle(tester);
        await tester.enterText(field('Quantity'), '10');
        await tester.enterText(field('Price per share (USD)'), '120');
        await tester.tap(byConfirm('Add transaction').last);
        await h.settle(tester);

        expect(find.textContaining('Only 3 shares held'), findsOneWidget);
        final txs = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).watchTransactions().first))!;
        expect(txs.length, 1);
        await h.dispose(tester);
      });

      testWidgets('editing a transaction updates it; deleting asks for confirmation', (tester) async {
        final h = await startWithPortfolio(tester);
        await tester.runAsync(() async {
          final repo = PortfolioRepositoryImpl(h.db, h.clock);
          final pid = (await repo.watchPortfolios().first).single.id;
          await repo.addTransaction(buy('AAPL', '2024-01-02', 3, 50, portfolio: pid));
        });
        await h.settle(tester);

        await tester.tap(find.text('Recent transactions').first);
        await tester.tap(find.textContaining('BUY').first);
        await h.settle(tester);
        expect(find.text('Edit transaction'), findsOneWidget);

        await tester.enterText(field('Quantity'), '4');
        await tester.tap(byConfirm('Save changes'));
        await h.settle(tester, frames: 20);
        var txs = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).watchTransactions().first))!;
        expect(txs.single.quantity, D('4'));

        await tester.tap(find.textContaining('BUY').first);
        await h.settle(tester);
        await tester.tap(find.text('Delete').last);
        await h.settle(tester);
        expect(find.text('Delete transaction?'), findsOneWidget);
        await tester.tap(find.text('Delete').last);
        await h.settle(tester, frames: 20);
        txs = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).watchTransactions().first))!;
        expect(txs, isEmpty);
        await h.dispose(tester);
      });
    });
  }
}

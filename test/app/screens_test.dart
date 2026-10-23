import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/domain/entities/enums.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
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
      Future<AppHarness> start(
        WidgetTester tester, {
        bool seed = true,
        Size size = const Size(1400, 1000),
        Future<void> Function(AppHarness h, PortfolioRepositoryImpl repo)? seedWith,
      }) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        h.market.setQuote(fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.', sector: 'Technology'));
        h.market.setQuote(fakeQuote('MSFT', price: 400, prev: 404, name: 'Microsoft Corp.', sector: 'Technology'));
        h.market.daily['AAPL'] = fakeCandles('2024-04-01', [for (var i = 0; i < 60; i++) 170 + i * 0.5]);
        h.market.searchResponse = const SearchResponse(
          results: [SearchResult(symbol: 'AAPL', name: 'Apple Inc.', quoteType: 'EQUITY', exchange: 'NASDAQ')],
          news: [NewsItem(title: 'Apple launches thing', url: 'https://example.com/a', publisher: 'Reuters')],
        );
        if (seed) {
          await tester.runAsync(() async {
            final repo = PortfolioRepositoryImpl(h.db, h.clock);
            final a = await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
            final b = await repo.createPortfolio(const NewPortfolio(name: 'Income'));
            await repo.addTransactions([
              buy('AAPL', '2024-01-02', 10, 150, portfolio: a),
              buy('MSFT', '2024-02-01', 5, 380, portfolio: a),
              buy('AAPL', '2024-03-01', 2, 170, portfolio: b),
            ]);
          });
        }
        if (seedWith != null) await tester.runAsync(() => seedWith(h, PortfolioRepositoryImpl(h.db, h.clock)));
        await h.pump(tester, size: size);
        return h;
      }

      void go(AppHarness h, String location) => h.container.read(routerProvider).go(location);

      testWidgets('portfolios: list shows values, create a portfolio, archive and delete', (tester) async {
        final h = await start(tester);
        go(h, Routes.portfolios);
        await h.settle(tester);

        expect(find.text('Growth'), findsWidgets);
        expect(find.text('Income'), findsWidgets);
        expect(find.text(r'$4,000.00'), findsOneWidget); // Growth: 10*200 + 5*400 = 4000
        expect(find.text(r'$400.00'), findsOneWidget); // Income: 2*200

        await tester.tap(byAction('New portfolio').first);
        await h.settle(tester);
        await tester.enterText(field('Name'), 'Crypto');
        await tester.tap(byConfirm('Create portfolio'));
        await h.settle(tester, frames: 20);
        expect(find.text('Crypto'), findsWidgets);

        // Duplicate names are rejected.
        await tester.tap(byAction('New portfolio').first);
        await h.settle(tester);
        await tester.enterText(field('Name'), 'growth');
        await tester.tap(byConfirm('Create portfolio'));
        await h.settle(tester);
        expect(find.text('A portfolio with this name already exists'), findsOneWidget);
        await tester.tap(byAction('Close').last);
        await h.settle(tester);

        // Archive Crypto via its menu.
        await tester.tap(byAction('Portfolio actions').last);
        await h.settle(tester);
        await tester.tap(find.text('Archive'));
        await h.settle(tester, frames: 20);
        expect(find.text('Archived'), findsOneWidget);

        // Delete it permanently from the archived list.
        await tester.tap(find.text('Delete').last);
        await h.settle(tester);
        await tester.tap(find.text('Delete portfolio'));
        await h.settle(tester, frames: 20);
        expect(find.text('Archived'), findsNothing);
        await h.dispose(tester);
      });

      testWidgets('portfolio detail: holdings, transactions and allocation tabs', (tester) async {
        final h = await start(tester);
        final pid = (await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).getPortfolios()))!.first.id;
        go(h, Routes.portfolio(pid));
        await h.settle(tester);

        expect(find.text('Growth'), findsWidgets);
        expect(find.text('Apple Inc.'), findsWidgets);
        expect(find.text('Microsoft Corp.'), findsWidgets);

        await tester.tap(find.text('Transactions'));
        await h.settle(tester);
        expect(find.textContaining('BUY'), findsWidgets);

        await tester.tap(find.text('Allocation'));
        await h.settle(tester);
        expect(find.text('Allocation'), findsWidgets);
        await h.dispose(tester);
      });

      testWidgets('holding detail shows position stats and cost basis', (tester) async {
        final h = await start(tester);
        final pid = (await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).getPortfolios()))!.first.id;
        go(h, Routes.holding(pid, 'AAPL'));
        await h.settle(tester, frames: 20);

        expect(find.text('AAPL'), findsWidgets);
        expect(find.text('Quantity'), findsOneWidget);
        expect(find.text('Cost basis (average cost)'), findsOneWidget);
        expect(find.text(r'$2,000.00'), findsWidgets); // market value 10 * 200
        expect(find.text('Transactions'), findsWidgets);
        await h.dispose(tester);
      });

      testWidgets('markets: create a watchlist, add a symbol, open the quote page', (tester) async {
        final h = await start(tester);
        go(h, Routes.markets);
        await h.settle(tester);
        expect(find.text('Track what you are watching'), findsOneWidget);

        await tester.tap(find.text('Create watchlist'));
        await h.settle(tester);
        await tester.tap(find.text('Save'));
        await h.settle(tester, frames: 20);
        expect(find.text('This watchlist is empty'), findsOneWidget);

        await tester.tap(byAction('Add symbol').first);
        await h.settle(tester);
        await tester.enterText(find.descendant(of: anyDialog(), matching: find.byType(EditableText)).first, 'aapl');
        await tester.pump(const Duration(milliseconds: 400));
        await h.settle(tester, frames: 4);
        await tester.tap(find.text('Apple Inc.').last);
        await h.settle(tester, frames: 20);

        final lists = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).getWatchlists()))!;
        expect(lists.single.symbols, ['AAPL']);
        expect(h.market.refreshCalls.any((s) => s.contains('AAPL')), isTrue);

        // Row shows the cached price and opens the quote page.
        expect(find.textContaining('200.00'), findsWidgets);
        await tester.tap(find.text('Apple Inc.').first);
        await h.settle(tester, frames: 25);
        expect(find.text('Key statistics'), findsOneWidget);
        expect(find.text('News'), findsOneWidget);
        expect(find.text('Apple launches thing'), findsOneWidget);
        expect(find.text('Previous close'), findsOneWidget);
        await h.dispose(tester);
      });

      testWidgets('quote screen handles a symbol with no data', (tester) async {
        final h = await start(tester);
        go(h, Routes.quote('ZZZZ'));
        await h.settle(tester, frames: 25);
        expect(find.text('Symbol not found'), findsOneWidget);
        await h.dispose(tester);
      });

      testWidgets('income: totals, unrecorded dividends can be recorded with one tap', (tester) async {
        final h = await start(
          tester,
          seed: false,
          seedWith: (h, repo) async {
            final pid = await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
            await repo.addTransactions([
              buy('AAPL', '2024-01-02', 10, 150, portfolio: pid),
              dividendTx('AAPL', '2024-03-05', 10, '0.5', portfolio: pid),
            ]);
            h.market.dividends['AAPL'] = [
              DividendEvent(symbol: 'AAPL', exDate: DateTime.utc(2024, 3, 1), amount: 0.5),
              DividendEvent(symbol: 'AAPL', exDate: DateTime.utc(2024, 5, 10), amount: 0.5),
            ];
          },
        );
        go(h, Routes.income);
        await h.settle(tester, frames: 25);

        expect(find.text('Received (12 months)'), findsOneWidget);
        expect(find.text(r'$5.00'), findsWidgets);
        expect(find.text('Unrecorded dividends (1)'), findsOneWidget);

        await tester.tap(find.text('Record').first);
        await h.settle(tester, frames: 25);
        final txs = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).getTransactions()))!;
        expect(txs.where((t) => t.type.name == 'dividend').length, 2);
        expect(find.text('Unrecorded dividends (1)'), findsNothing);
        expect(find.text(r'$10.00'), findsWidgets);
        await h.dispose(tester);
      });

      testWidgets('income: Luno rewards are shown beside dividends, valued when received', (tester) async {
        final h = await start(
          tester,
          seed: false,
          seedWith: (h, repo) async {
            final pid = await repo.createPortfolio(const NewPortfolio(name: 'Luno – Main'));
            await repo.addTransactions([
              tx(TxType.reward, 'LUNO:XBTMYR', '2024-05-01', quantity: '0.001', price: 260000, portfolio: pid),
              tx(TxType.reward, 'LUNO:XBTMYR', '2024-03-01', quantity: '0.002', price: 250000, portfolio: pid),
            ]);
          },
        );
        go(h, Routes.income);
        await h.settle(tester, frames: 25);

        expect(find.text('No income yet'), findsNothing);
        expect(find.text('Rewards (12 months)'), findsOneWidget);
        expect(find.text(r'$760.00'), findsWidgets); // 260 + 500
        expect(find.text('Rewards by month'), findsOneWidget);
        expect(find.text('Rewards by asset (12 months)'), findsOneWidget);
        expect(find.text('LUNO:XBTMYR'), findsWidgets);
        await h.dispose(tester);
      });

      testWidgets('quote: a Luno market shows bid, ask, spread and 24h volume instead of equity statistics', (tester) async {
        final h = await start(tester, seed: false);
        h.market.setQuote(
          Quote(
            symbol: 'LUNO:XBTMYR',
            name: 'Bitcoin',
            price: 300000,
            previousClose: 297000,
            bid: 299900,
            ask: 300100,
            volume: 12.5,
            currency: 'MYR',
            quoteType: 'CRYPTOCURRENCY',
            exchange: 'Luno',
            marketState: 'REGULAR',
            fetchedAt: DateTime.utc(2024, 6, 1),
          ),
        );
        h.market.daily['LUNO:XBTMYR'] = fakeCandles('2024-01-01', [for (var i = 0; i < 30; i++) 290000 + i * 300]);
        go(h, Routes.quote('LUNO:XBTMYR'));
        await h.settle(tester, frames: 30);

        expect(find.text('Luno market'), findsOneWidget);
        for (final label in ['Bid', 'Ask', 'Spread', '24h volume', 'Status']) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        expect(find.text('Trading'), findsOneWidget);
        expect(find.text('P/E (TTM)'), findsNothing);
        expect(find.text('24/7 market'), findsOneWidget);
        await h.dispose(tester);
      });
    });
  }
}

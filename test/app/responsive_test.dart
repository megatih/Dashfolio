import 'package:dashfolio/app/app_settings.dart' show AppSkin;
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  const sizes = {'phone': Size(360, 740), 'tablet': Size(820, 1100), 'desktop': Size(1440, 900)};

  for (final skin in AppSkin.values) {
    for (final entry in sizes.entries) {
      for (final brightness in Brightness.values) {
        testWidgets('every screen lays out without exceptions: ${skin.name} / ${entry.key} / ${brightness.name}', (tester) async {
          final h = AppHarness.create(skin: skin);
          await h.completeOnboarding();
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
          for (final q in [
            fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.', sector: 'Technology'),
            fakeQuote(
              'MSFT',
              price: 400,
              prev: 404,
              name: 'Microsoft Corporation (a very long company name for wrapping)',
              sector: 'Technology',
            ),
            fakeQuote('BTC-USD', price: 65000.5, prev: 64000, type: 'CRYPTOCURRENCY', name: 'Bitcoin USD'),
            fakeQuote('SAP.DE', price: 150, prev: 149, currency: 'EUR', name: 'SAP SE'),
            fakeQuote('EURUSD=X', price: 1.08, prev: 1.08, type: 'CURRENCY'),
          ]) {
            h.market.setQuote(q);
          }
          h.market.daily['AAPL'] = fakeCandles('2024-03-01', [for (var i = 0; i < 90; i++) 150 + i * 0.6]);
          h.market.daily['MSFT'] = fakeCandles('2024-03-01', [for (var i = 0; i < 90; i++) 380 + (i % 7)]);
          h.market.dividends['AAPL'] = [DividendEvent(symbol: 'AAPL', exDate: DateTime.utc(2024, 5, 10), amount: 0.25)];
          h.market.splits['MSFT'] = [SplitEvent(symbol: 'MSFT', date: DateTime.utc(2024, 4, 1), numerator: 2, denominator: 1)];
          h.market.searchResponse = const SearchResponse(
            results: [SearchResult(symbol: 'AAPL', name: 'Apple Inc.', quoteType: 'EQUITY', exchange: 'NASDAQ')],
            news: [
              NewsItem(title: 'A reasonably long news headline that must wrap on narrow screens', url: 'https://x.test', publisher: 'Wire'),
            ],
          );

          late int pid;
          await tester.runAsync(() async {
            final repo = PortfolioRepositoryImpl(h.db, h.clock);
            pid = await repo.createPortfolio(const NewPortfolio(name: 'Growth with a rather long name'));
            final other = await repo.createPortfolio(const NewPortfolio(name: 'Income'));
            await repo.addTransactions([
              buy('AAPL', '2024-01-02', 10, 150, portfolio: pid),
              buy('MSFT', '2024-02-01', '5.5', 380, portfolio: pid),
              sell('MSFT', '2024-04-01', 1, 410, portfolio: pid),
              dividendTx('AAPL', '2024-03-05', 10, '0.25', portfolio: pid),
              buy('BTC-USD', '2024-02-10', '0.123456', 42000, portfolio: pid),
              buy('SAP.DE', '2024-02-11', 3, 120, currency: 'EUR', fx: '1.08', portfolio: other),
            ]);
            final w = await repo.createWatchlist('Tech');
            for (final s in ['AAPL', 'MSFT', 'NVDA']) {
              await repo.addToWatchlist(w, s);
            }
          });
          await h.pump(tester, size: entry.value);

          final routes = [
            Routes.dashboard,
            Routes.portfolios,
            Routes.portfolio(pid),
            Routes.holding(pid, 'AAPL'),
            Routes.holding(pid, 'MSFT'),
            Routes.markets,
            Routes.quote('AAPL'),
            Routes.income,
            Routes.settings,
            Routes.importCsv,
          ];
          for (final r in routes) {
            h.container.read(routerProvider).go(r);
            await h.settle(tester, frames: 14);
            expect(tester.takeException(), isNull, reason: 'layout exception on $r at ${entry.key}');
          }
          await h.dispose(tester);
        });
      }
    }
  }

  for (final skin in AppSkin.values) {
    testWidgets('dashboard and tables survive large text scaling without overflow: ${skin.name}', (tester) async {
      final h = AppHarness.create(skin: skin);
      await h.completeOnboarding();
      h.market.setQuote(fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.', sector: 'Technology'));
      await tester.runAsync(() async {
        final repo = PortfolioRepositoryImpl(h.db, h.clock);
        final pid = await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
        await repo.addTransaction(buy('AAPL', '2024-01-02', 10, 150, portfolio: pid));
      });
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await h.pump(tester, size: const Size(420, 900));
      for (final r in [Routes.dashboard, Routes.portfolios, Routes.markets, Routes.income, Routes.settings]) {
        h.container.read(routerProvider).go(r);
        await h.settle(tester, frames: 14);
        expect(tester.takeException(), isNull, reason: 'overflow with 1.5x text on $r');
      }
      await h.dispose(tester);
    });
  }
}

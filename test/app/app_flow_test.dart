import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/features/lock/lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/fonts.dart';
import '../support/fake_market_data.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final skin in AppSkin.values) {
    group(skin.name, () {
      testWidgets('first run shows the welcome flow, then lands on an empty dashboard', (tester) async {
        final h = AppHarness.create(skin: skin);
        await h.pump(tester);

        expect(find.text('Welcome to Dashfolio'), findsOneWidget);
        expect(find.textContaining('not financial advice'), findsOneWidget);

        await tester.tap(find.text('Accept and get started'));
        await h.settle(tester, frames: 20);

        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Add your first transaction'), findsOneWidget);
        final portfolios = (await tester.runAsync(() => h.container.read(portfolioRepositoryProvider).watchPortfolios().first))!;
        expect(portfolios.single.name, 'My portfolio');
        await h.dispose(tester);
      });

      testWidgets('dashboard values holdings from transactions and cached quotes', (tester) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        h.market.setQuote(fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.', sector: 'Technology'));
        await tester.runAsync(() async {
          final repo = PortfolioRepositoryImpl(h.db, h.clock);
          final pid = await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
          await repo.addTransaction(buy('AAPL', '2024-01-02', 10, 150, portfolio: pid));
        });
        await h.pump(tester);

        // 10 shares * $200 = $2,000.00; day change 10 * (200-190) = +$100.00
        expect(find.text(r'$2,000.00'), findsWidgets);
        expect(find.textContaining('+\$100.00'), findsWidgets);
        expect(find.text('AAPL'), findsWidgets);
        await h.dispose(tester);
      });

      testWidgets('layout adapts: bottom bar on phones, side navigation on desktop', (tester) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        await h.pump(tester, size: const Size(400, 800));
        expect(find.byType(AppTabBar), findsOneWidget);
        expect(find.byType(AppSideNav), findsNothing);

        await tester.binding.setSurfaceSize(null);
        tester.view.physicalSize = const Size(1400, 900);
        await h.settle(tester);
        expect(find.byType(AppSideNav), findsOneWidget);
        expect(find.byType(AppTabBar), findsNothing);
        await h.dispose(tester);
      });

      testWidgets('navigating between tabs shows each screen', (tester) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        await h.pump(tester);

        for (final entry in {
          'Portfolios': 'No portfolios yet',
          'Markets': 'Track what you are watching',
          'Income': 'No income yet',
          'Settings': 'Appearance',
        }.entries) {
          await tester.tap(find.descendant(of: find.byType(AppSideNav), matching: find.text(entry.key)).first);
          await h.settle(tester);
          expect(find.text(entry.value), findsWidgets, reason: entry.key);
        }
        await h.dispose(tester);
      });

      testWidgets('app lock gates the app until the PIN is entered', (tester) async {
        final h = AppHarness.create(skin: skin);
        await h.completeOnboarding();
        await tester.runAsync(() async {
          await h.pins.write('s', const PinHasher(iterations: 10).hash('2468', 's'));
          await SettingsRepositoryLike(h.db).set('lock_enabled', 'true');
        });
        await h.pump(tester, size: const Size(500, 900));

        expect(find.text('Dashfolio is locked'), findsOneWidget);
        expect(find.text('Dashboard'), findsNothing);

        for (final d in ['1', '1', '1', '1']) {
          await tester.tap(find.text(d).first);
          await tester.pump();
        }
        await tester.tap(find.text('Unlock'));
        await h.settle(tester);
        expect(find.text('Incorrect PIN'), findsOneWidget);

        for (final d in ['2', '4', '6', '8']) {
          await tester.tap(find.text(d).first);
          await tester.pump();
        }
        await tester.tap(find.text('Unlock'));
        await h.settle(tester, frames: 20);
        expect(find.text('Dashfolio is locked'), findsNothing);
        expect(find.text('Dashboard'), findsWidgets);
        await h.dispose(tester);
      });
    });
  }
}

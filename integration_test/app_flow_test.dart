// End-to-end flow on a real device/desktop window with in-memory storage and fake market data:
//   onboarding -> new portfolio -> add transaction -> dashboard shows the valued holding.
//
//   flutter test integration_test -d macos      (or windows / linux / an iOS simulator)
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/domain/entities/market.dart';
import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/app_harness.dart';
import '../test/support/fake_market_data.dart';
import '../test/support/finders.dart';
import '../test/support/fonts.dart';

Finder _field(String label) =>
    find.descendant(of: find.byWidgetPredicate((w) => w is AppTextField && w.label == label), matching: find.byType(EditableText));

/// On a device the clock is real: route transitions only finish once real time has passed, not just pumped time.
Future<void> _letRouteFinish(WidgetTester tester, AppHarness h) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
  await h.settle(tester, frames: 8);
}

/// Desktop windows get a fixed size; on a phone the test uses the real screen, so the phone layout is what runs.
Size? _viewSize(WidgetTester tester) => defaultTargetPlatform == TargetPlatform.iOS ? null : const Size(1280, 900);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  final onPhone = defaultTargetPlatform == TargetPlatform.iOS;

  // The detailed purchase flow is written for a desktop window; phones run the smoke test below.
  for (final skin in AppSkin.values) {
    testWidgets('first run to a valued holding on the dashboard: ${skin.name}', (tester) async {
      final h = AppHarness.create(skin: skin);
      h.market.setQuote(fakeQuote('AAPL', price: 100, prev: 98, name: 'Apple Inc.'));
      h.market.searchResponse = const SearchResponse(
        results: [SearchResult(symbol: 'AAPL', name: 'Apple Inc.', quoteType: 'EQUITY', exchange: 'NASDAQ')],
        news: [],
      );
      await h.pump(tester, size: _viewSize(tester));

      // Onboarding.
      expect(find.text('Welcome to Dashfolio'), findsOneWidget);
      await tester.ensureVisible(find.text('Accept and get started'));
      await tester.tap(find.text('Accept and get started'));
      await h.settle(tester, frames: 25);
      expect(find.text('Add your first transaction'), findsOneWidget);

      // Add a purchase through the form.
      // Desktops have the toolbar action; on a phone the empty state's button is the visible way in.
      await tester.tap((onPhone ? find.text('Add transaction') : byAction('Add transaction (Ctrl/Cmd+N)')).hitTestable().first);
      await _letRouteFinish(tester, h);
      await tester.enterText(
        (onPhone ? find.byType(EditableText).hitTestable() : find.descendant(of: anyDialog(), matching: find.byType(EditableText))).first,
        'aapl',
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700))); // search debounce
      await h.settle(tester, frames: 8);
      await tester.ensureVisible(find.text('Apple Inc.').hitTestable().first);
      await tester.tap(find.text('Apple Inc.').hitTestable().first);
      await h.settle(tester);
      await tester.ensureVisible(_field('Quantity'));
      await tester.enterText(_field('Quantity'), '5');
      await tester.ensureVisible(_field('Price per share (USD)'));
      await tester.enterText(_field('Price per share (USD)'), '80');
      await tester.ensureVisible(byConfirm('Add transaction').hitTestable().last);
      await tester.tap(byConfirm('Add transaction').hitTestable().last);
      await h.settle(tester, frames: 25);

      // 5 shares at $100 = $500.00 (cost $400.00).
      expect(find.text(r'$500.00'), findsWidgets);
      expect(find.text('AAPL'), findsWidgets);
      expect((await tester.runAsync(() => PortfolioRepositoryImpl(h.db, h.clock).getTransactions()))!.length, 1);

      await h.dispose(tester);
    });
  }

  testWidgets('the interface style switches live in the running app', (tester) async {
    final h = AppHarness.create(cupertinoAvailable: true);
    await h.completeOnboarding();
    await h.pump(tester, size: _viewSize(tester));
    await tester.tap(find.text('Settings').first);
    await h.settle(tester, frames: 20);
    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.tap(find.text('Cupertino'));
    await h.settle(tester, frames: 25);
    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.text('Interface style'), findsOneWidget);

    await tester.tap(find.text('Neumorphic'));
    await h.settle(tester, frames: 25);
    expect(find.byType(MaterialApp), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('phone: fresh install starts in Cupertino, onboards, and navigates by tab bar', (tester) async {
    final h = AppHarness.create(cupertinoAvailable: true);
    await h.pump(tester, size: _viewSize(tester));

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.text('Welcome to Dashfolio'), findsOneWidget);
    await tester.ensureVisible(find.text('Accept and get started'));
    await tester.tap(find.text('Accept and get started'));
    await h.settle(tester, frames: 25);
    expect(find.text('Add your first transaction'), findsOneWidget);

    for (final tab in ['Portfolios', 'Markets', 'Income', 'Settings', 'Dashboard']) {
      await tester.tap(find.text(tab).last);
      await h.settle(tester, frames: 15);
      expect(tester.takeException(), isNull, reason: 'layout exception on $tab');
    }
    await h.dispose(tester);
  });
}

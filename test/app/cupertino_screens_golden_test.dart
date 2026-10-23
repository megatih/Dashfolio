@Tags(['golden'])
library;

import 'package:dashfolio/app/app_settings.dart' show AppSkin;
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart' show Brightness, Size;
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

/// Full Cupertino screens: the phone shell (tab bar), the tablet shell (sidebar) and macOS (sidebar, inline toolbar, denser
/// controls), light and dark.
void main() {
  setUpAll(loadAppFonts);

  const cases = {'phone': Size(390, 844), 'desktop': Size(1200, 800), 'macos': Size(1200, 800)};
  const routes = {'dashboard': Routes.dashboard, 'portfolios': Routes.portfolios, 'settings': Routes.settings};

  for (final b in Brightness.values) {
    for (final c in cases.entries) {
      for (final r in routes.entries) {
        testWidgets('cupertino ${r.key} / ${c.key} / ${b.name}', (tester) async {
          if (c.key == 'macos') {
            debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          }
          final h = AppHarness.create(skin: AppSkin.cupertino);
          await h.completeOnboarding();
          tester.platformDispatcher.platformBrightnessTestValue = b;
          addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
          h.market.setQuote(fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.', sector: 'Technology'));
          await tester.runAsync(() async {
            final repo = PortfolioRepositoryImpl(h.db, h.clock);
            final pid = await repo.createPortfolio(const NewPortfolio(name: 'Growth'));
            await repo.addTransaction(buy('AAPL', '2024-01-02', 10, 150, portfolio: pid));
          });
          await h.pump(tester, size: c.value);
          h.container.read(routerProvider).go(r.value);
          await h.settle(tester, frames: 16);
          expect(tester.takeException(), isNull);
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('goldens/cupertino_${r.key}_${c.key}_${b.name}.png'));
          await h.dispose(tester);
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }
  }
}

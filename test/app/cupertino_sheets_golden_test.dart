@Tags(['golden'])
library;

import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/domain/repositories/portfolio_repository.dart';
import 'package:dashfolio/features/portfolios/portfolio_form.dart';
import 'package:dashfolio/features/shell/app_shell.dart';
import 'package:dashfolio/features/transactions/transaction_form.dart';
import 'package:flutter/cupertino.dart' show CupertinoApp;
import 'package:flutter/widgets.dart' show BuildContext, Navigator, Text;
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart' show Brightness, Size;
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_market_data.dart';
import '../support/fonts.dart';

/// Cupertino sheets and alerts: the form sheet (phone and macOS) and the destructive alert.
void main() {
  setUpAll(loadAppFonts);

  const cases = {'phone': (Size(390, 844), TargetPlatform.iOS), 'macos': (Size(1200, 800), TargetPlatform.macOS)};

  for (final b in Brightness.values) {
    for (final c in cases.entries) {
      Future<(AppHarness, int)> start(WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = c.value.$2;
        final h = AppHarness.create(skin: AppSkin.cupertino);
        await h.completeOnboarding();
        tester.platformDispatcher.platformBrightnessTestValue = b;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        h.market.setQuote(fakeQuote('AAPL', price: 200, prev: 190, name: 'Apple Inc.'));
        final pid = (await tester.runAsync(
          () => PortfolioRepositoryImpl(h.db, h.clock).createPortfolio(const NewPortfolio(name: 'Growth')),
        ))!;
        await h.pump(tester, size: c.value.$1);
        return (h, pid);
      }

      BuildContext shellContext(WidgetTester tester) => tester.element(find.byType(AppShell));

      testWidgets('cupertino transaction sheet / ${c.key} / ${b.name}', (tester) async {
        final (h, pid) = await start(tester);
        showTransactionForm(shellContext(tester), portfolioId: pid);
        await h.settle(tester, frames: 20);
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(CupertinoApp), matchesGoldenFile('goldens/cupertino_sheet_transaction_${c.key}_${b.name}.png'));
        await h.dispose(tester);
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('cupertino portfolio sheet / ${c.key} / ${b.name}', (tester) async {
        final (h, _) = await start(tester);
        showPortfolioForm(shellContext(tester));
        await h.settle(tester, frames: 20);
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(CupertinoApp), matchesGoldenFile('goldens/cupertino_sheet_portfolio_${c.key}_${b.name}.png'));
        await h.dispose(tester);
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('cupertino dialog / ${c.key} / ${b.name}', (tester) async {
        final (h, _) = await start(tester);
        showAppModal<void>(
          shellContext(tester),
          builder: (ctx) => AppDialog(
            title: 'Restore backup',
            actions: [
              AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
              AppButton(label: 'Merge', onPressed: () => Navigator.pop(ctx)),
              AppButton(label: 'Replace everything', kind: AppButtonKind.danger, onPressed: () => Navigator.pop(ctx)),
            ],
            child: const Text('2 portfolios · 14 transactions · 1 watchlists'),
          ),
        );
        await h.settle(tester, frames: 20);
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(CupertinoApp), matchesGoldenFile('goldens/cupertino_dialog_${c.key}_${b.name}.png'));
        await h.dispose(tester);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  }
}

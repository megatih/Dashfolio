import 'package:dashfolio/app/app_settings.dart';
import 'package:dashfolio/data/backup/backup_service.dart';
import 'package:dashfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:dashfolio/data/repositories/settings_repository_impl.dart';
import 'package:dashfolio/design_system/app/app_ui.dart' show AppSideNav, AppTabBar;
import 'package:dashfolio/app/providers.dart';
import 'package:dashfolio/app/skin.dart';
import 'package:dashfolio/domain/repositories/settings_repository.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fonts.dart';

Future<String?> storedSkin(WidgetTester tester, AppHarness h) =>
    tester.runAsync(() => h.container.read(settingsRepositoryProvider).get(SettingKeys.uiSkin)).then((v) => v);

String location(AppHarness h) => h.container.read(routerProvider).state.uri.path;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('switching the interface style is live, keeps the page, and persists', (tester) async {
    final h = AppHarness.create(cupertinoAvailable: true);
    await h.completeOnboarding();
    await h.pump(tester);
    h.container.read(routerProvider).go(Routes.settings);
    await h.settle(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CupertinoApp), findsNothing);
    expect(find.text('Interface style'), findsOneWidget);

    await tester.tap(find.text('Cupertino'));
    await h.settle(tester, frames: 20);

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsNothing);
    expect(location(h), Routes.settings, reason: 'the user stays on Settings');
    expect(find.text('Interface style'), findsOneWidget);
    expect(await storedSkin(tester, h), 'cupertino');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Neumorphic'));
    await h.settle(tester, frames: 20);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(location(h), Routes.settings);
    expect(await storedSkin(tester, h), 'neumorphic');
    await h.dispose(tester);
  });

  testWidgets('the row is hidden where the Cupertino skin is not available', (tester) async {
    final h = AppHarness.create();
    await h.completeOnboarding();
    await h.pump(tester);
    h.container.read(routerProvider).go(Routes.settings);
    await h.settle(tester);

    expect(find.text('Interface style'), findsNothing);
    expect(find.text('Appearance'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('a fresh install starts in Cupertino and remembers it when onboarding finishes', (tester) async {
    final h = AppHarness.create(cupertinoAvailable: true);
    await h.pump(tester);

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.text('Welcome to Dashfolio'), findsOneWidget);

    await tester.tap(find.text('Accept and get started'));
    await h.settle(tester, frames: 20);

    expect(await storedSkin(tester, h), 'cupertino');
    expect(h.container.read(effectiveSkinProvider), AppSkin.cupertino);
    await h.dispose(tester);
  });

  testWidgets('an install that finished onboarding before the feature keeps the original look', (tester) async {
    final h = AppHarness.create(cupertinoAvailable: true);
    await tester.runAsync(() => SettingsRepositoryLike(h.db).set(SettingKeys.disclaimerAccepted, 'true'));
    await h.pump(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CupertinoApp), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('a restored Cupertino choice is ignored where the skin is unavailable, but kept', (tester) async {
    final h = AppHarness.create();
    await h.completeOnboarding();
    await tester.runAsync(() => SettingsRepositoryLike(h.db).set(SettingKeys.uiSkin, 'cupertino'));
    await h.pump(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(await storedSkin(tester, h), 'cupertino');
    await h.dispose(tester);
  });

  testWidgets('macOS always gets a sidebar in the Cupertino skin, even in a narrow window', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final h = AppHarness.create(skin: AppSkin.cupertino);
    await h.completeOnboarding();
    await h.pump(tester, size: const Size(400, 800));

    expect(find.byType(AppSideNav), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);
    await h.dispose(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('iPhone-sized windows keep the tab bar in the Cupertino skin', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final h = AppHarness.create(skin: AppSkin.cupertino);
    await h.completeOnboarding();
    await h.pump(tester, size: const Size(400, 800));

    expect(find.byType(AppTabBar), findsOneWidget);
    expect(find.byType(AppSideNav), findsNothing);
    await h.dispose(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the interface style travels with a backup', (tester) async {
    final h = AppHarness.create();
    await tester.runAsync(() async {
      await SettingsRepositoryLike(h.db).set(SettingKeys.uiSkin, 'cupertino');
      final settings = SettingsRepositoryImpl(h.db);
      final backup = BackupService(PortfolioRepositoryImpl(h.db, h.clock), settings, h.clock);
      final json = await backup.exportAll();
      await settings.set(SettingKeys.uiSkin, 'neumorphic');
      await backup.restore(json, RestoreMode.replace);
      expect(await settings.get(SettingKeys.uiSkin), 'cupertino');
    });
    await tester.runAsync(h.db.close);
  });
}

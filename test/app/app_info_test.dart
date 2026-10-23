import 'package:dashfolio/app/app_info.dart';
import 'package:dashfolio/routing/router.dart';
import 'package:dashfolio/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  group('AppInfo', () {
    test('label joins version and build number', () {
      expect(const AppInfo(version: '1.2.3', buildNumber: '45').label, '1.2.3 (45)');
      expect(const AppInfo(version: '1.2.3', buildNumber: '').label, '1.2.3');
    });

    test('parseBuildDate reads ISO-8601 and ignores empty or invalid values', () {
      expect(AppInfo.parseBuildDate('2026-10-23T08:30:00Z'), DateTime.utc(2026, 10, 23, 8, 30));
      expect(AppInfo.parseBuildDate(''), isNull);
      expect(AppInfo.parseBuildDate('not a date'), isNull);
    });
  });

  testWidgets('Settings About shows version, build number and a development-build date fallback', (tester) async {
    final h = AppHarness.create();
    await h.completeOnboarding();
    await h.pump(tester);
    h.container.read(routerProvider).go(Routes.settings);
    await h.settle(tester);

    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Build 1'), findsOneWidget);
    expect(find.text('Build date: development build'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Settings About shows the formatted build date when one is stamped', (tester) async {
    final h = AppHarness.create();
    h.appInfo = AppInfo(version: '2.0.0', buildNumber: '7', buildDate: DateTime(2026, 10, 23, 12));
    await h.completeOnboarding();
    await h.pump(tester);
    h.container.read(routerProvider).go(Routes.settings);
    await h.settle(tester);

    expect(find.text('Version 2.0.0'), findsOneWidget);
    expect(find.text('Build 7'), findsOneWidget);
    expect(find.text('Build date: Oct 23, 2026'), findsOneWidget);
    await h.dispose(tester);
  });
}

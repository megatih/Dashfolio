import 'dart:io';

import 'package:dashfolio/design_system/cupertino/cupertino_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Cupertino skin takes every size from the platform token tables (SPEC_CUPERTINO.md §4.2).
void main() {
  Future<CupertinoTypography> typography(WidgetTester tester, TargetPlatform platform) async {
    debugDefaultTargetPlatformOverride = platform;
    late CupertinoTypography t;
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) {
            t = CupertinoTypography.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return t;
  }

  testWidgets('iOS uses the Large Dynamic Type sizes', (tester) async {
    final t = await typography(tester, TargetPlatform.iOS);
    expect(
      [
        t.largeTitle,
        t.title1,
        t.title2,
        t.title3,
        t.headline,
        t.body,
        t.callout,
        t.subheadline,
        t.footnote,
        t.caption1,
        t.caption2,
      ].map((s) => s.fontSize),
      [34, 28, 22, 20, 17, 17, 16, 15, 13, 12, 11],
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('macOS uses the macOS text styles, not a scaled iOS ramp', (tester) async {
    final t = await typography(tester, TargetPlatform.macOS);
    expect(
      [
        t.largeTitle,
        t.title1,
        t.title2,
        t.title3,
        t.headline,
        t.body,
        t.callout,
        t.subheadline,
        t.footnote,
        t.caption1,
        t.caption2,
      ].map((s) => s.fontSize),
      [26, 22, 17, 15, 13, 13, 13, 13, 11, 11, 10],
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('no text style falls below the platform minimum', (tester) async {
    for (final (platform, floor) in [(TargetPlatform.iOS, 11.0), (TargetPlatform.macOS, 10.0)]) {
      final t = await typography(tester, platform);
      final slots = t.toTextTheme();
      for (final s in [slots.displayLarge, slots.headlineMedium, slots.titleSmall, slots.bodyMedium, slots.bodySmall, slots.labelSmall]) {
        expect(s!.fontSize, greaterThanOrEqualTo(floor), reason: '$platform');
      }
    }
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('touch controls keep 44 pt rows; macOS rows are denser', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(CupertinoMetrics.current.rowHeight, 44);
    expect(CupertinoMetrics.current.minHit, 44);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(CupertinoMetrics.current.rowHeight, lessThan(44));
    expect(CupertinoMetrics.current.pointer, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  test('the Cupertino kit has no hard-coded text sizes or styles outside the theme file', () {
    final literal = RegExp(r'fontSize\s*:|(?<![A-Za-z])TextStyle\(');
    final offenders = <String>[];
    for (final f in Directory('lib/design_system/cupertino').listSync().whereType<File>()) {
      if (f.path.endsWith('cupertino_theme.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (literal.hasMatch(lines[i])) offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(offenders, isEmpty, reason: 'read sizes from CupertinoTypography / CupertinoMetrics instead');
  });
}

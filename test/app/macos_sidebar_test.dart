import 'package:dashfolio/app/app_settings.dart' show AppSkin;
import 'package:dashfolio/design_system/cupertino/cu_nav.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart' show Size;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fonts.dart';

/// On macOS the Cupertino sidebar is as wide as its content: compact, with no clipped or overlapping text at any text size.
void main() {
  setUpAll(loadAppFonts);

  for (final scale in [1.0, 1.5]) {
    testWidgets('macOS sidebar fits its header and labels at ${scale}x text', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final h = AppHarness.create(skin: AppSkin.cupertino);
      await h.completeOnboarding();
      await h.pump(tester, size: const Size(1200, 800));

      final sidebar = tester.getRect(find.byType(CuSideNav));
      if (scale == 1.0) expect(sidebar.width, lessThan(200));
      expect(sidebar.width, greaterThanOrEqualTo(160));

      for (final label in ['Dashfolio', 'Dashboard', 'Portfolios', 'Markets', 'Income', 'Settings']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(label).first);
        expect(paragraph.didExceedMaxLines, isFalse, reason: '$label is truncated');
        expect(sidebar.contains(tester.getRect(find.text(label).first).centerRight), isTrue, reason: '$label sticks out');
      }

      final name = tester.getRect(find.text('Dashfolio'));
      final toggle = tester.getRect(find.bySemanticsLabel('Hide sidebar'));
      expect(name.right, lessThanOrEqualTo(toggle.left), reason: 'name overlaps the hide button');
      expect(tester.takeException(), isNull);

      await h.dispose(tester);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}

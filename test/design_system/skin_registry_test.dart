import 'dart:io';

import 'package:dashfolio/design_system/app/skin_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screens never branch on the skin except through registered `SkinBuilder` overrides (`SPEC_CUPERTINO.md` §8).
void main() {
  test('SkinBuilder and AppSkinScope are used only by files in the override registry', () {
    final users = <String>{};
    for (final root in ['lib/features', 'lib/routing', 'lib/app']) {
      for (final f in Directory(root).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        if (const {'lib/app/app.dart', 'lib/app/skin.dart', 'lib/app/app_settings.dart'}.contains(f.path)) continue;
        final text = f.readAsStringSync();
        if (RegExp(r'\bSkinBuilder\b|\bAppSkinScope\b|\bAppSkin\.|\beffectiveSkinProvider\b').hasMatch(text)) {
          users.add(f.path.replaceFirst('lib/', ''));
        }
      }
    }
    // Settings reads/writes the skin setting itself (the Interface style row) and is allowed to.
    users.remove('features/settings/settings_screen.dart');
    users.remove('features/settings/welcome_screen.dart');
    expect(users, kSkinOverrides.keys.toSet(), reason: 'register the override in kSkinOverrides and in the spec, or use a facade widget');
  });
}

import 'package:dashfolio/app/app_settings.dart';
import 'package:dashfolio/app/skin.dart';
import 'package:dashfolio/domain/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.skin', () {
    test('missing and unknown values parse to null', () {
      expect(AppSettings.fromMap({}).skin, isNull);
      expect(AppSettings.fromMap({SettingKeys.uiSkin: 'material'}).skin, isNull);
    });

    test('round trips through the stored name', () {
      for (final s in AppSkin.values) {
        expect(AppSettings.fromMap({SettingKeys.uiSkin: AppSettings.skinName(s)}).skin, s);
      }
    });
  });

  group('resolveSkin', () {
    AppSkin resolve({required bool available, AppSkin? stored, bool accepted = false}) =>
        resolveSkin(cupertinoAvailable: available, stored: stored, disclaimerAccepted: accepted);

    test('fresh install gets Cupertino where it is available', () {
      expect(resolve(available: true), AppSkin.cupertino);
    });

    test('an install that already accepted the disclaimer keeps Neumorphic until it chooses', () {
      expect(resolve(available: true, accepted: true), AppSkin.neumorphic);
    });

    test('an explicit choice wins either way', () {
      expect(resolve(available: true, stored: AppSkin.neumorphic), AppSkin.neumorphic);
      expect(resolve(available: true, stored: AppSkin.cupertino, accepted: true), AppSkin.cupertino);
    });

    test('unavailable always means Neumorphic, even with a restored Cupertino value', () {
      expect(resolve(available: false), AppSkin.neumorphic);
      expect(resolve(available: false, stored: AppSkin.cupertino), AppSkin.neumorphic);
    });
  });
}

import 'package:flutter/widgets.dart';

import '../../app/app_settings.dart' show AppSkin;

export '../../app/app_settings.dart' show AppSkin;

/// Tells facade widgets which kit to render. Set once by the app root.
///
/// Only facade widgets and [SkinBuilder] read this; screens must not (see `SPEC_CUPERTINO.md` §7.7).
class AppSkinScope extends InheritedWidget {
  const AppSkinScope({super.key, required this.skin, required super.child});

  final AppSkin skin;

  static AppSkin of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppSkinScope>()?.skin ?? AppSkin.neumorphic;

  @override
  bool updateShouldNotify(AppSkinScope old) => skin != old.skin;
}

/// The only sanctioned way for screen code to diverge by skin. Every use must be listed in the override registry
/// (`SPEC_CUPERTINO.md` §8); `skin_registry_test.dart` enforces that.
class SkinBuilder extends StatelessWidget {
  const SkinBuilder({super.key, required this.neumorphic, required this.cupertino});

  final WidgetBuilder neumorphic;
  final WidgetBuilder cupertino;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => neumorphic(context),
    AppSkin.cupertino => cupertino(context),
  };
}

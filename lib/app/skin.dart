import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';
import 'providers.dart';

/// Whether the Cupertino skin can be chosen here: iOS and macOS in release, every platform in debug.
/// A provider (rather than a bare platform check) so tests can override it.
final cupertinoSkinAvailableProvider = Provider<bool>((ref) {
  if (kDebugMode) return true;
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
});

/// Pure resolution of the skin to render; see `SPEC_CUPERTINO.md` §3.3.
AppSkin resolveSkin({required bool cupertinoAvailable, required AppSkin? stored, required bool disclaimerAccepted}) {
  if (!cupertinoAvailable) return AppSkin.neumorphic;
  if (stored != null) return stored;
  // Never chosen: fresh installs get Cupertino, installs that predate the feature keep the original look.
  return disclaimerAccepted ? AppSkin.neumorphic : AppSkin.cupertino;
}

final effectiveSkinProvider = Provider<AppSkin>((ref) {
  final available = ref.watch(cupertinoSkinAvailableProvider);
  final (stored, accepted) = ref.watch(appSettingsProvider.select((s) => (s.skin, s.disclaimerAccepted)));
  return resolveSkin(cupertinoAvailable: available, stored: stored, disclaimerAccepted: accepted);
});

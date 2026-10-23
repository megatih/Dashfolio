/// Screen files allowed to diverge by skin through `SkinBuilder`, with the reason for each.
///
/// Mirrors the override registry in `SPEC_CUPERTINO.md` §8. `skin_registry_test.dart` fails when a file under
/// `lib/features/`, `lib/app/` or `lib/routing/` uses `SkinBuilder` without being listed here (or the reverse).
/// Prefer extending the facade over adding an entry.
const Map<String, String> kSkinOverrides = {
  'features/lock/lock_screen.dart': 'O1: round iOS-style PIN keys instead of raised rectangular keys',
};

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// System font families the Cupertino skin asks for. They do not exist in the test engine (it would fall back to Ahem
/// blocks), so Inter stands in with similar metrics. Goldens therefore guard layout, not typography.
const _systemFontStandIns = [
  '.SF Pro Text',
  '.SF Pro Display',
  '.AppleSystemUIFont',
  '.SF UI Text',
  '.SF UI Display',
  'CupertinoSystemText',
  'CupertinoSystemDisplay',
];

/// Loads the bundled Inter font so goldens render real glyphs instead of Ahem blocks.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final family in ['Inter', ..._systemFontStandIns]) {
    final loader = FontLoader(family)..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
  }
  final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
    ..addFont(rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'));
  await icons.load();
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens are written once against the `App*` facade (`SPEC_CUPERTINO.md` §7.7). They must not reach for a kit
/// directly or use stock Material widgets that need a Material ancestor.
const _screenRoots = ['lib/features', 'lib/routing', 'lib/app'];

/// The app root builds `MaterialApp`/`CupertinoApp` and the kit themes, so it is the one place that sees the kits.
const _rootAllowList = {'lib/app/app.dart'};

final _bannedImports = RegExp(r"import '[^']*design_system/(neu/|cupertino/|design_system\.dart)");

final _bannedIdentifiers = <String, RegExp>{
  for (final name in [
    'NeuTheme',
    'showDialog',
    'showModalBottomSheet',
    'PopupMenuButton',
    'PopupMenuItem',
    'CheckedPopupMenuItem',
    'showMenu',
    'showDatePicker',
    'showLicensePage',
    'SnackBar',
    'ScaffoldMessenger',
    'ListTile',
    'RefreshIndicator',
    'Tooltip',
    'Scaffold',
    'AppBar',
    'TextButton',
    'IconButton',
    'Divider',
    'CircularProgressIndicator',
    'LinearProgressIndicator',
    'ReorderableListView',
    'InkWell',
    'Material',
    'DropdownButton',
    'DropdownMenuItem',
    'DataTable',
    'TextField',
    'Switch',
    'Slider',
    'Checkbox',
  ])
    name: RegExp('\\b$name\\b'),
  'Neu*': RegExp(r'\bNeu[A-Z]\w*'),
  'Icons.*': RegExp(r'\bIcons\.\w+'),
};

Iterable<File> _screenFiles() sync* {
  for (final root in _screenRoots) {
    for (final e in Directory(root).listSync(recursive: true)) {
      if (e is File && e.path.endsWith('.dart') && !_rootAllowList.contains(e.path)) yield e;
    }
  }
}

String _code(String line) {
  final i = line.indexOf('//');
  return i < 0 ? line : line.substring(0, i);
}

void main() {
  test('screens import only the App* facade', () {
    final bad = <String>[];
    for (final f in _screenFiles()) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (_bannedImports.hasMatch(line)) bad.add('${f.path}:${i + 1}: $line');
      }
    }
    expect(bad, isEmpty, reason: 'import design_system/app/app_ui.dart instead');
  });

  test('screens use no kit or stock Material widgets directly', () {
    final bad = <String>[];
    for (final f in _screenFiles()) {
      for (final (i, line) in f.readAsLinesSync().indexed) {
        final code = _code(line);
        for (final e in _bannedIdentifiers.entries) {
          if (e.value.hasMatch(code)) bad.add('${f.path}:${i + 1}: ${e.key}');
        }
      }
    }
    expect(bad, isEmpty, reason: 'use the App* facade widget (see SPEC_CUPERTINO.md §7.3)');
  });

  test('the kits do not import each other or the facade', () {
    for (final (dir, banned) in [('lib/design_system/neu', 'cupertino/'), ('lib/design_system/cupertino', 'neu/')]) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      for (final f in d.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final text = f.readAsStringSync();
        expect(text.contains("design_system/$banned") || text.contains("'../$banned"), isFalse, reason: f.path);
        expect(text.contains('/app/'), isFalse, reason: '${f.path} must not import the facade');
      }
    }
  });
}

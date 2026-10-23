@Tags(['golden'])
library;

import 'package:dashfolio/design_system/app/app_ui.dart' show AppChangeBadge, AppSkin, AppSkinScope;
import 'package:dashfolio/design_system/cupertino/cupertino_theme.dart';
import 'package:dashfolio/design_system/design_system.dart';
import 'package:dashfolio/design_system/gallery.dart';
import 'package:flutter/cupertino.dart' show CupertinoApp, CupertinoPageScaffold;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fonts.dart';

Widget _app(Brightness b, Widget child) => MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(b), home: child);

Widget _swatch(Brightness b, String name, Widget child) => _GoldenCase(brightness: b, child: child);

class _GoldenCase extends StatelessWidget {
  const _GoldenCase({required this.brightness, required this.child});
  final Brightness brightness;
  final Widget child;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(brightness),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final b in Brightness.values) {
    final name = b.name;

    testWidgets('surfaces ($name)', (tester) async {
      tester.view.physicalSize = const Size(560, 220);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _swatch(
          b,
          'surfaces',
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final s in NeuShape.values)
                NeuSurface(shape: s, depth: 3, width: 100, height: 80, alignment: Alignment.center, child: Text(s.name)),
            ],
          ),
        ),
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/surfaces_$name.png'));
    });

    testWidgets('buttons and controls ($name)', (tester) async {
      tester.view.physicalSize = const Size(640, 260);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _swatch(
          b,
          'controls',
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              NeuButton(label: 'Normal', onPressed: () {}),
              NeuButton(label: 'Primary', kind: NeuButtonKind.primary, onPressed: () {}),
              NeuButton(label: 'Danger', kind: NeuButtonKind.danger, onPressed: () {}),
              const NeuButton(label: 'Disabled'),
              NeuIconButton(icon: Icons.refresh, tooltip: 'Refresh', onPressed: () {}),
              NeuSwitch(value: true, onChanged: (_) {}),
              NeuSwitch(value: false, onChanged: (_) {}),
              NeuSegmentedControl<int>(
                segments: const [NeuSegment(1, '1D'), NeuSegment(2, '1W'), NeuSegment(3, '1M')],
                selected: 2,
                onChanged: (_) {},
              ),
              const NeuChip(label: 'Chip', selected: true),
              const SizedBox(width: 200, child: NeuProgress(value: 0.6)),
              const AppChangeBadge(ratio: 0.0123),
              const AppChangeBadge(ratio: -0.0456),
            ],
          ),
        ),
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/controls_$name.png'));
    });

    testWidgets('inputs and table ($name)', (tester) async {
      tester.view.physicalSize = const Size(520, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _swatch(
          b,
          'inputs',
          SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NeuTextField(label: 'Symbol', hint: 'e.g. AAPL', prefixIcon: Icons.search),
                const SizedBox(height: 12),
                const NeuTextField(label: 'Quantity', errorText: 'Must be greater than zero'),
                const SizedBox(height: 12),
                NeuCard(
                  padding: EdgeInsets.zero,
                  child: NeuDataTable<(String, String)>(
                    columns: [
                      NeuColumn(id: 's', label: 'Symbol', width: 140, flex: 1, cell: (c, r) => Text(r.$1)),
                      NeuColumn(id: 'v', label: 'Value', numeric: true, width: 120, cell: (c, r) => Text(r.$2)),
                    ],
                    rows: const [('AAPL', '1,200.50'), ('MSFT', '980.00'), ('NVDA', '450.00')],
                    sortColumnId: 'v',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/inputs_table_$name.png'));
    });

    testWidgets('empty state and navigation ($name)', (tester) async {
      tester.view.physicalSize = const Size(420, 520);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          b,
          Scaffold(
            body: const EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No holdings yet',
              message: 'Add your first transaction to see your portfolio.',
              actionLabel: 'Add transaction',
              onAction: _noop,
            ),
            bottomNavigationBar: NeuNavBar(
              items: const [
                NeuNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
                NeuNavItem(label: 'Portfolios', icon: Icons.folder_outlined),
                NeuNavItem(label: 'Markets', icon: Icons.show_chart),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/empty_nav_$name.png'));
    });
  }

  testWidgets('gallery builds without overflow in both themes', (tester) async {
    for (final b in Brightness.values) {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app(b, const DesignGallery()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.reset);
  });

  // The same facade catalogue in both skins. Cupertino goldens guard layout; the test engine has no SF font.
  for (final b in Brightness.values) {
    for (final skin in AppSkin.values) {
      testWidgets('facade catalogue: ${skin.name} (${b.name})', (tester) async {
        tester.view.physicalSize = const Size(480, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          AppSkinScope(
            skin: skin,
            child: switch (skin) {
              AppSkin.neumorphic => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildTheme(b),
                home: const Scaffold(body: AppCatalogue()),
              ),
              AppSkin.cupertino => CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: buildCupertinoTheme(b),
                builder: (context, child) => CupertinoRoot(child: child!),
                home: const CupertinoPageScaffold(child: SafeArea(child: AppCatalogue())),
              ),
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(AppSkinScope), matchesGoldenFile('goldens/catalogue_${skin.name}_${b.name}.png'));
      });

      testWidgets('form catalogue: ${skin.name} (${b.name})', (tester) async {
        tester.view.physicalSize = const Size(480, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          AppSkinScope(
            skin: skin,
            child: switch (skin) {
              AppSkin.neumorphic => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildTheme(b),
                home: const Scaffold(body: AppFormCatalogue()),
              ),
              AppSkin.cupertino => CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: buildCupertinoTheme(b),
                builder: (context, child) => CupertinoRoot(child: child!),
                home: const CupertinoPageScaffold(child: SafeArea(child: AppFormCatalogue())),
              ),
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await expectLater(find.byType(AppSkinScope), matchesGoldenFile('goldens/form_catalogue_${skin.name}_${b.name}.png'));
      });
    }
  }
}

void _noop() {}

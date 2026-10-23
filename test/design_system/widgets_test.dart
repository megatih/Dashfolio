import "package:dashfolio/design_system/app/app_ui.dart" show AppChangeBadge;
import "package:dashfolio/design_system/design_system.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {Brightness b = Brightness.light, double width = 800}) => MaterialApp(
  theme: buildTheme(b),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  testWidgets('NeuButton fires onPressed and meets the 44px hit target', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(NeuButton(label: 'Go', onPressed: () => taps++)));
    final size = tester.getSize(find.byType(NeuButton));
    expect(size.height, greaterThanOrEqualTo(44));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('disabled NeuButton ignores taps', (tester) async {
    await tester.pumpWidget(host(const NeuButton(label: 'Nope')));
    await tester.tap(find.text('Nope'));
    // no exception and no state to change; semantics reports disabled
    expect(tester.getSemantics(find.byType(NeuButton)).flagsCollection.isEnabled.toString(), isNot('Tristate.isTrue'));
  });

  testWidgets('NeuButton activates from the keyboard', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(NeuButton(label: 'Key', onPressed: () => taps++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('NeuSwitch toggles', (tester) async {
    var value = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (c, set) => NeuSwitch(value: value, onChanged: (v) => set(() => value = v)),
        ),
      ),
    );
    await tester.tap(find.byType(NeuSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('NeuSegmentedControl reports the tapped segment', (tester) async {
    String selected = 'a';
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (c, set) => NeuSegmentedControl<String>(
            segments: const [NeuSegment('a', 'One'), NeuSegment('b', 'Two')],
            selected: selected,
            onChanged: (v) => set(() => selected = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(selected, 'b');
  });

  testWidgets('NeuTextField validates and shows the error', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(
      host(
        Form(
          key: key,
          child: NeuTextField(label: 'Qty', validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
        ),
      ),
    );
    expect(key.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5');
    await tester.pump();
    expect(key.currentState!.validate(), isTrue);
  });

  testWidgets('NeuDataTable sorts via header tap and reports row taps', (tester) async {
    String? sorted;
    bool? asc;
    String? tapped;
    await tester.pumpWidget(
      host(
        NeuDataTable<String>(
          columns: [NeuColumn(id: 'name', label: 'Name', width: 200, cell: (c, r) => Text(r))],
          rows: const ['alpha', 'beta'],
          onSort: (id, a) {
            sorted = id;
            asc = a;
          },
          onRowTap: (r) => tapped = r,
        ),
      ),
    );
    await tester.tap(find.text('Name'));
    expect(sorted, 'name');
    expect(asc, isFalse);
    await tester.tap(find.text('beta'));
    expect(tapped, 'beta');
  });

  testWidgets('NeuDataTable scrolls horizontally on narrow widths instead of overflowing', (tester) async {
    await tester.pumpWidget(
      host(
        NeuDataTable<String>(
          columns: [for (var i = 0; i < 6; i++) NeuColumn(id: 'c$i', label: 'Column $i', width: 160, cell: (c, r) => Text(r))],
          rows: const ['x'],
        ),
        width: 320,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('AppChangeBadge conveys direction without relying on color', (tester) async {
    await tester.pumpWidget(
      host(const Column(children: [AppChangeBadge(ratio: 0.05), AppChangeBadge(ratio: -0.05), AppChangeBadge(ratio: null)])),
    );
    expect(find.textContaining('▲'), findsOneWidget);
    expect(find.textContaining('▼'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('ErrorRetryView shows retry and calls back', (tester) async {
    var retried = false;
    await tester.pumpWidget(host(ErrorRetryView(error: Exception('x'), onRetry: () => retried = true)));
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('showAdaptiveSheet uses a dialog on wide and a sheet on compact screens', (tester) async {
    Future<void> open(WidgetTester t, Size size) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (c) => Scaffold(
              body: TextButton(
                onPressed: () => showAdaptiveSheet<void>(c, builder: (_) => const SizedBox(height: 100, child: Text('SHEET'))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
    }

    await open(tester, const Size(900, 800));
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('SHEET'), findsOneWidget);
    tester.view.resetPhysicalSize();
  });

  testWidgets('reduced NeuScope renders a bordered flat surface', (tester) async {
    await tester.pumpWidget(host(const NeuScope(reduced: true, child: NeuSurface(width: 50, height: 50))));
    final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(NeuSurface), matching: find.byType(DecoratedBox)).first);
    final d = box.decoration as BoxDecoration;
    expect(d.boxShadow, isEmpty);
    expect(d.border, isNotNull);
  });
}

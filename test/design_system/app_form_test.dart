import 'package:dashfolio/design_system/app/app_ui.dart';
import 'package:dashfolio/design_system/neu/theme.dart' show buildTheme;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_test/flutter_test.dart';

import '../support/fonts.dart';

Widget host(AppSkin skin, Widget child, {double width = 390}) {
  final body = Center(
    child: SizedBox(
      width: width,
      child: SingleChildScrollView(child: child),
    ),
  );
  return AppSkinScope(
    skin: skin,
    child: skin == AppSkin.cupertino
        ? CupertinoApp(home: CupertinoPageScaffold(child: body))
        : MaterialApp(
            theme: buildTheme(Brightness.light),
            home: Scaffold(body: body),
          ),
  );
}

/// The form primitives behave the same in both skins: same callbacks, same labels, every option reachable.
void main() {
  setUpAll(loadAppFonts);

  for (final skin in AppSkin.values) {
    group(skin.name, () {
      testWidgets('AppSection shows its title, rows, footer, and AppButtonGroup buttons fire', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          host(
            skin,
            AppSection(
              title: 'Your data',
              footer: 'Stored on this device.',
              children: [
                AppFormRow(
                  label: 'Lock',
                  control: AppSwitch(value: false, onChanged: (_) {}),
                ),
                AppButtonGroup(
                  buttons: [AppButton(label: 'Back up', onPressed: () => taps++)],
                ),
              ],
            ),
          ),
        );
        expect(find.text('Your data'), findsOneWidget);
        expect(find.text('Lock'), findsOneWidget);
        expect(find.text('Stored on this device.'), findsOneWidget);
        await tester.tap(find.text('Back up'));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('AppSegmented keeps all seven options reachable on a phone', (tester) async {
        var selected = 3;
        await tester.pumpWidget(
          host(
            skin,
            StatefulBuilder(
              builder: (context, set) => AppSegmented<int>(
                dense: true,
                selected: selected,
                onChanged: (v) => set(() => selected = v),
                segments: [
                  for (final i in [1, 2, 3, 4, 5, 6, 7]) AppSegment(i, 'R$i'),
                ],
              ),
            ),
          ),
        );
        if (skin == AppSkin.cupertino) {
          // More than five options become a pop-up menu on a phone.
          await tester.tap(find.text('R3'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('R7'));
          await tester.pumpAndSettle();
          expect(selected, 7);
        } else {
          await tester.tap(find.text('R7'));
          await tester.pumpAndSettle();
          expect(selected, 7);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('AppSelect picks a value', (tester) async {
        String? value = 'a';
        await tester.pumpWidget(
          host(
            skin,
            StatefulBuilder(
              builder: (context, set) => AppSelect<String>(
                label: 'Currency',
                value: value,
                options: const [AppOption('a', 'Alpha'), AppOption('b', 'Beta')],
                onChanged: (v) => set(() => value = v),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beta').last);
        await tester.pumpAndSettle();
        expect(value, 'b');
      });

      testWidgets('AppSheetScaffold confirms, shows the destructive action and the footer note', (tester) async {
        var confirmed = 0;
        var deleted = 0;
        await tester.pumpWidget(
          host(
            skin,
            AppSheetScaffold(
              title: 'Edit',
              confirmLabel: 'Save changes',
              shortConfirmLabel: 'Save',
              onConfirm: () => confirmed++,
              destructiveLabel: 'Delete',
              onDestructive: () => deleted++,
              footer: 'Please fix the highlighted fields.',
              children: [
                AppSection(
                  bare: true,
                  children: [AppTextField(label: 'Name', controller: TextEditingController())],
                ),
              ],
            ),
          ),
        );
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Please fix the highlighted fields.'), findsOneWidget);
        await tester.tap(find.text(skin == AppSkin.cupertino ? 'Save' : 'Save changes'));
        await tester.tap(find.text('Delete'));
        expect(confirmed, 1);
        expect(deleted, 1);
        expect(tester.takeException(), isNull);
      });
    });
  }
}

import 'package:dashfolio/design_system/design_system.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contrastRatio sanity checks', () {
    expect(contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)), closeTo(21, 0.01));
    expect(contrastRatio(const Color(0xFF777777), const Color(0xFF777777)), closeTo(1, 0.001));
  });

  for (final t in {'light': NeuTheme.light, 'dark': NeuTheme.dark}.entries) {
    group('${t.key} theme contrast (>= 4.5:1 on surface and inset wells)', () {
      final n = t.value;
      final backgrounds = {'surface': n.surface, 'surfaceAlt': n.surfaceAlt};
      final foregrounds = {
        'text': n.text,
        'textMuted': n.textMuted,
        'accent': n.accent,
        'gain': n.gain,
        'loss': n.loss,
        'warning': n.warning,
      };
      for (final bg in backgrounds.entries) {
        for (final fg in foregrounds.entries) {
          test('${fg.key} on ${bg.key}', () {
            expect(contrastRatio(fg.value, bg.value), greaterThanOrEqualTo(4.5));
          });
        }
      }
      test('onAccent on accent', () => expect(contrastRatio(n.onAccent, n.accent), greaterThanOrEqualTo(4.5)));
    });
  }
}

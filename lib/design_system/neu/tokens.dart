import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Neumorphic design tokens exposed as a [ThemeExtension].
@immutable
class NeuTheme extends ThemeExtension<NeuTheme> {
  const NeuTheme({
    required this.brightness,
    required this.surface,
    required this.surfaceAlt,
    required this.highlight,
    required this.shadow,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.gain,
    required this.loss,
    required this.warning,
    required this.outline,
  });

  final Brightness brightness;
  final Color surface;

  /// Slightly different tone for inset wells / table stripes.
  final Color surfaceAlt;
  final Color highlight;
  final Color shadow;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color gain;
  final Color loss;
  final Color warning;
  final Color outline;

  bool get isDark => brightness == Brightness.dark;

  // Radii
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 20;

  // 4-pt spacing scale
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24, s8 = 32, s10 = 40;

  /// Minimum interactive size.
  static const double minHit = 44;

  /// Offset and blur for depth levels 0–4.
  static const List<double> _offsets = [0, 2, 4, 7, 11];
  static const List<double> _blurs = [0, 5, 10, 16, 24];

  double offsetFor(int depth) => _offsets[depth.clamp(0, 4)];
  double blurFor(int depth) => _blurs[depth.clamp(0, 4)];

  /// Raised (extruded) shadows at [depth].
  List<BoxShadow> raised(int depth) {
    if (depth <= 0) return const [];
    final o = offsetFor(depth), b = blurFor(depth);
    return [
      BoxShadow(color: highlight, offset: Offset(-o, -o), blurRadius: b),
      BoxShadow(color: shadow, offset: Offset(o, o), blurRadius: b),
    ];
  }

  /// Shadows for an inset (pressed / concave) well at [depth].
  List<BoxShadow> inset(int depth) {
    final o = offsetFor(depth.clamp(1, 4)), b = blurFor(depth.clamp(1, 4));
    return [
      BoxShadow(color: shadow, offset: Offset(o, o), blurRadius: b),
      BoxShadow(color: highlight, offset: Offset(-o, -o), blurRadius: b),
    ];
  }

  Color pnl(num value) => value > 0 ? gain : (value < 0 ? loss : textMuted);

  static const light = NeuTheme(
    brightness: Brightness.light,
    surface: Color(0xFFE6EBF1),
    surfaceAlt: Color(0xFFDDE3EB),
    highlight: Color(0xFFFFFFFF),
    shadow: Color(0xFFA3B1C6),
    text: Color(0xFF1B2330),
    textMuted: Color(0xFF4F5B6E),
    accent: Color(0xFF2557D6),
    onAccent: Color(0xFFFFFFFF),
    gain: Color(0xFF0B6B35),
    loss: Color(0xFFB3202A),
    warning: Color(0xFF8A5A00),
    outline: Color(0xFFC3CCD8),
  );

  static const dark = NeuTheme(
    brightness: Brightness.dark,
    surface: Color(0xFF22262E),
    surfaceAlt: Color(0xFF1C1F26),
    highlight: Color(0xFF2E343E),
    shadow: Color(0xFF14171C),
    text: Color(0xFFE8ECF3),
    textMuted: Color(0xFFA3ACBB),
    accent: Color(0xFF86A8FF),
    onAccent: Color(0xFF0B1020),
    gain: Color(0xFF4ADE80),
    loss: Color(0xFFFF7B7B),
    warning: Color(0xFFF5B942),
    outline: Color(0xFF3A414D),
  );

  static NeuTheme of(BuildContext context) =>
      Theme.of(context).extension<NeuTheme>() ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  NeuTheme copyWith({Color? surface, Color? accent}) => NeuTheme(
    brightness: brightness,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt,
    highlight: highlight,
    shadow: shadow,
    text: text,
    textMuted: textMuted,
    accent: accent ?? this.accent,
    onAccent: onAccent,
    gain: gain,
    loss: loss,
    warning: warning,
    outline: outline,
  );

  @override
  NeuTheme lerp(ThemeExtension<NeuTheme>? other, double t) {
    if (other is! NeuTheme) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return NeuTheme(
      brightness: t < 0.5 ? brightness : other.brightness,
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      highlight: l(highlight, other.highlight),
      shadow: l(shadow, other.shadow),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      gain: l(gain, other.gain),
      loss: l(loss, other.loss),
      warning: l(warning, other.warning),
      outline: l(outline, other.outline),
    );
  }
}

/// Convenience accessors on [BuildContext].
extension NeuContext on BuildContext {
  NeuTheme get neu => NeuTheme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
}

double lerpD(double a, double b, double t) => lerpDouble(a, b, t)!;

/// Text styles that render numbers in tabular figures so columns align.
const tabularFigures = [FontFeature.tabularFigures()];

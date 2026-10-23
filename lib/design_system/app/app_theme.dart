import 'package:flutter/material.dart' show TextTheme, Theme;
import 'package:flutter/widgets.dart';

import '../cupertino/cupertino_theme.dart';
import '../neu/tokens.dart';
import 'skin_scope.dart';

/// Tabular (fixed-width) figures so columns of numbers line up.
const tabularFigures = [FontFeature.tabularFigures()];

/// Spacing, radii and hit sizes shared by both skins.
abstract final class AppSpace {
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 20;

  /// 4-pt spacing scale.
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24, s8 = 32, s10 = 40;

  static const double minHit = 44;
}

/// Skin-neutral semantic colors. Screens read these instead of a kit's tokens.
@immutable
class AppTheme {
  const AppTheme({
    required this.isDark,
    required this.surface,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.gain,
    required this.loss,
    required this.warning,
    required this.chartSeries,
    required this.tooltipBackground,
    required this.tooltipForeground,
  });

  final bool isDark;
  final Color surface;
  final Color outline;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color gain;
  final Color loss;
  final Color warning;

  /// Ordered, distinguishable colors for chart series and allocation slices.
  final List<Color> chartSeries;

  /// Chart touch tooltips: an inverted bubble in the Neumorphic skin, a grouped-background bubble in Cupertino.
  final Color tooltipBackground;
  final Color tooltipForeground;

  /// Gain / loss / muted color for a signed value.
  Color pnl(num value) => value > 0 ? gain : (value < 0 ? loss : textMuted);

  factory AppTheme.of(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => AppTheme.fromNeu(NeuTheme.of(context)),
    AppSkin.cupertino => AppTheme.fromCupertino(CupertinoPalette.of(context)),
  };

  factory AppTheme.fromNeu(NeuTheme n) => AppTheme(
    isDark: n.isDark,
    surface: n.surface,
    outline: n.outline,
    text: n.text,
    textMuted: n.textMuted,
    accent: n.accent,
    onAccent: n.onAccent,
    gain: n.gain,
    loss: n.loss,
    warning: n.warning,
    chartSeries: n.isDark ? _neuDarkSeries : _neuLightSeries,
    tooltipBackground: n.text,
    tooltipForeground: n.surface,
  );

  factory AppTheme.fromCupertino(CupertinoPalette p) => AppTheme(
    isDark: p.isDark,
    surface: p.groupedBackground,
    outline: p.separator,
    text: p.label,
    textMuted: p.secondaryLabel,
    accent: p.accent,
    onAccent: p.onAccent,
    gain: p.gain,
    loss: p.loss,
    warning: p.warning,
    chartSeries: p.chartSeries,
    tooltipBackground: p.secondaryGroupedBackground,
    tooltipForeground: p.label,
  );

  static const _neuDarkSeries = [
    Color(0xFF86A8FF),
    Color(0xFF4ADE80),
    Color(0xFFF5B942),
    Color(0xFFFF7B7B),
    Color(0xFFB69CFF),
    Color(0xFF5FD4D6),
    Color(0xFFFF9F6B),
    Color(0xFFD18BE8),
  ];
  static const _neuLightSeries = [
    Color(0xFF2557D6),
    Color(0xFF0B7A3E),
    Color(0xFFB36B00),
    Color(0xFFC0392B),
    Color(0xFF6B46C1),
    Color(0xFF0E8A8E),
    Color(0xFFC4521A),
    Color(0xFF9B3FB4),
  ];
}

extension AppContext on BuildContext {
  AppTheme get app => AppTheme.of(this);

  /// The text scale of the active skin (Inter for Neumorphic, the system font for Cupertino).
  TextTheme get text => switch (AppSkinScope.of(this)) {
    AppSkin.neumorphic => Theme.of(this).textTheme,
    AppSkin.cupertino => CupertinoTypography.of(this).toTextTheme(),
  };
}

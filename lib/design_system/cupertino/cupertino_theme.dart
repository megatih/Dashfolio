import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart' show Material, MaterialType, NoSplash, TextTheme, Theme, ThemeData;

/// Theme for the Cupertino skin: system blue tint, SF text, system backgrounds. [brightness] null follows the platform.
CupertinoThemeData buildCupertinoTheme(Brightness? brightness) =>
    CupertinoThemeData(brightness: brightness, primaryColor: CupertinoColors.systemBlue, applyThemeToAll: true);

/// System colors resolved for the current brightness. The only color source for Cupertino widgets.
@immutable
class CupertinoPalette {
  const CupertinoPalette({
    required this.isDark,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.separator,
    required this.background,
    required this.groupedBackground,
    required this.secondaryGroupedBackground,
    required this.fill,
    required this.secondaryFill,
    required this.quaternaryFill,
    required this.barBackground,
    required this.sidebarBackground,
    required this.accent,
    required this.onAccent,
    required this.gain,
    required this.loss,
    required this.warning,
    required this.chartSeries,
  });

  final bool isDark;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color separator;
  final Color background;
  final Color groupedBackground;
  final Color secondaryGroupedBackground;
  final Color fill;
  final Color secondaryFill;
  final Color quaternaryFill;

  /// Translucent bar material (navigation and tab bars; blurred behind).
  final Color barBackground;
  final Color sidebarBackground;
  final Color accent;
  final Color onAccent;
  final Color gain;
  final Color loss;
  final Color warning;
  final List<Color> chartSeries;

  static const _series = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemGreen,
    CupertinoColors.systemOrange,
    CupertinoColors.systemRed,
    CupertinoColors.systemPurple,
    CupertinoColors.systemTeal,
    CupertinoColors.systemPink,
    CupertinoColors.systemIndigo,
  ];

  factory CupertinoPalette.of(BuildContext context) {
    Color r(CupertinoDynamicColor c) => CupertinoDynamicColor.resolve(c, context);
    return CupertinoPalette(
      isDark: CupertinoTheme.brightnessOf(context) == Brightness.dark,
      label: r(CupertinoColors.label),
      secondaryLabel: r(CupertinoColors.secondaryLabel),
      tertiaryLabel: r(CupertinoColors.tertiaryLabel),
      separator: r(CupertinoColors.separator),
      background: r(CupertinoColors.systemBackground),
      groupedBackground: r(CupertinoColors.systemGroupedBackground),
      secondaryGroupedBackground: r(CupertinoColors.secondarySystemGroupedBackground),
      fill: r(CupertinoColors.tertiarySystemFill),
      secondaryFill: r(CupertinoColors.secondarySystemFill),
      quaternaryFill: r(CupertinoColors.quaternarySystemFill),
      barBackground: r(CupertinoColors.systemBackground).withValues(alpha: 0.82),
      sidebarBackground: r(CupertinoColors.secondarySystemBackground),
      accent: r(CupertinoColors.systemBlue),
      onAccent: CupertinoColors.white,
      gain: r(CupertinoColors.systemGreen),
      loss: r(CupertinoColors.systemRed),
      warning: r(CupertinoColors.systemOrange),
      chartSeries: [for (final c in _series) r(c)],
    );
  }
}

/// Sizes that differ between touch (iOS, iPadOS) and pointer (macOS) devices. The only source of Cupertino dimensions.
@immutable
class CupertinoMetrics {
  const CupertinoMetrics({
    required this.pointer,
    required this.rowHeight,
    required this.minHit,
    required this.groupRadius,
    required this.controlHeight,
    required this.largeControlHeight,
    required this.navIconSize,
    required this.iconSize,
    required this.switchScale,
    required this.sidebarWidth,
    required this.progressHeight,
  });

  /// True for macOS (mouse, keyboard, denser controls).
  final bool pointer;
  final double rowHeight;
  final double minHit;
  final double groupRadius;
  final double controlHeight;
  final double largeControlHeight;
  final double navIconSize;

  /// In-row and in-button symbol size.
  final double iconSize;
  final double switchScale;

  /// Sidebar width on touch devices; the minimum width on macOS, where the sidebar sizes to its content.
  final double sidebarWidth;
  final double progressHeight;

  /// Page margins and the width a form column stays within on wide screens.
  static const double inset = 16;
  static const double pageMarginRegular = 20;
  static const double sectionGap = 24;
  static const double readableWidth = 720;

  static const _touch = CupertinoMetrics(
    pointer: false,
    rowHeight: 44,
    minHit: 44,
    groupRadius: 12,
    controlHeight: 34,
    largeControlHeight: 50,
    navIconSize: 22,
    iconSize: 18,
    switchScale: 1,
    sidebarWidth: 260,
    progressHeight: 4,
  );
  static const _pointer = CupertinoMetrics(
    pointer: true,
    rowHeight: 28,
    minHit: 24,
    groupRadius: 10,
    controlHeight: 22,
    largeControlHeight: 28,
    navIconSize: 16,
    iconSize: 14,
    switchScale: 0.8,
    sidebarWidth: 160,
    progressHeight: 4,
  );

  static CupertinoMetrics get current => defaultTargetPlatform == TargetPlatform.macOS ? _pointer : _touch;

  /// Left and right page margin for the given window width.
  static double pageMargin(double width) => width < 600 ? inset : pageMarginRegular;
}

const _tabular = [FontFeature.tabularFigures()];

/// Apple's text styles on the system font, per platform (iOS Large Dynamic Type; macOS built-in styles). The only source of text
/// sizes for the Cupertino skin. The platform text scaler still applies on top.
@immutable
class CupertinoTypography {
  const CupertinoTypography({
    required this.largeTitle,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.headline,
    required this.body,
    required this.callout,
    required this.subheadline,
    required this.footnote,
    required this.caption1,
    required this.caption2,
    required this.rowTitle,
  });

  final TextStyle largeTitle;
  final TextStyle title1;
  final TextStyle title2;
  final TextStyle title3;
  final TextStyle headline;
  final TextStyle body;
  final TextStyle callout;
  final TextStyle subheadline;

  /// Secondary label color.
  final TextStyle footnote;
  final TextStyle caption1;

  /// Secondary label color.
  final TextStyle caption2;

  /// Emphasised row title.
  final TextStyle rowTitle;

  factory CupertinoTypography.of(BuildContext context) {
    final base = CupertinoTheme.of(context).textTheme.textStyle;
    final p = CupertinoPalette.of(context);
    final mac = CupertinoMetrics.current.pointer;
    TextStyle s(double ios, double mac_, FontWeight w, {Color? color, double? height}) => base.copyWith(
      fontSize: mac ? mac_ : ios,
      fontWeight: w,
      color: color ?? p.label,
      height: height,
      fontFeatures: _tabular,
      letterSpacing: 0,
    );
    return CupertinoTypography(
      largeTitle: s(34, 26, FontWeight.w700, height: 1.15),
      title1: s(28, 22, FontWeight.w700, height: 1.15),
      title2: s(22, 17, FontWeight.w700, height: 1.2),
      title3: s(20, 15, FontWeight.w600, height: 1.25),
      headline: s(17, 13, FontWeight.w700, height: 1.3),
      body: s(17, 13, FontWeight.w400, height: 1.3),
      callout: s(16, 13, FontWeight.w400, height: 1.3),
      subheadline: s(15, 13, FontWeight.w400, color: p.secondaryLabel, height: 1.3),
      footnote: s(13, 11, FontWeight.w400, color: p.secondaryLabel, height: 1.3),
      caption1: s(12, 11, FontWeight.w500, height: 1.2),
      caption2: s(11, 10, FontWeight.w500, color: p.secondaryLabel, height: 1.2),
      rowTitle: s(15, 13, FontWeight.w600, height: 1.3),
    );
  }

  /// The slots screens use through `context.text`.
  TextTheme toTextTheme() => TextTheme(
    displayLarge: largeTitle,
    displayMedium: title1,
    headlineMedium: title2,
    headlineSmall: title3,
    titleLarge: title3,
    titleMedium: headline,
    titleSmall: rowTitle,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: footnote,
    labelLarge: callout.copyWith(fontWeight: FontWeight.w600),
    labelMedium: caption1.copyWith(fontWeight: FontWeight.w600),
    labelSmall: caption2,
  );
}

/// Wraps the Cupertino app content: a default text style, and the transparent Material host plus theme that the few
/// documented Material exceptions need (reorderable lists, the licences page, chart tooltips). See `SPEC_CUPERTINO.md` §7.7.
class CupertinoRoot extends StatelessWidget {
  const CupertinoRoot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Theme(
      data: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        colorSchemeSeed: CupertinoColors.systemBlue,
      ),
      child: Material(
        type: MaterialType.transparency,
        // Inside the Material host, which would otherwise impose its own (Roboto) text style.
        child: DefaultTextStyle(style: CupertinoTheme.of(context).textTheme.textStyle, child: child),
      ),
    );
  }
}

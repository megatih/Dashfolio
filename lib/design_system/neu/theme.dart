import 'package:flutter/material.dart';

import 'tokens.dart';

const _fontFamily = 'Inter';

TextTheme _textTheme(NeuTheme n) {
  TextStyle s(double size, FontWeight w, {double? height, double? ls, Color? color}) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: size,
    fontWeight: w,
    height: height,
    letterSpacing: ls,
    color: color ?? n.text,
    fontFeatures: tabularFigures,
  );
  return TextTheme(
    displayLarge: s(44, FontWeight.w700, height: 1.1, ls: -1),
    displayMedium: s(34, FontWeight.w700, height: 1.15, ls: -0.5),
    headlineMedium: s(24, FontWeight.w700, height: 1.25),
    headlineSmall: s(20, FontWeight.w600, height: 1.3),
    titleLarge: s(18, FontWeight.w600, height: 1.3),
    titleMedium: s(16, FontWeight.w600, height: 1.35),
    titleSmall: s(14, FontWeight.w600, height: 1.35),
    bodyLarge: s(16, FontWeight.w400, height: 1.45),
    bodyMedium: s(14, FontWeight.w400, height: 1.45),
    bodySmall: s(12, FontWeight.w400, height: 1.4, color: n.textMuted),
    labelLarge: s(14, FontWeight.w600, height: 1.2),
    labelMedium: s(12, FontWeight.w600, height: 1.2, ls: 0.2),
    labelSmall: s(11, FontWeight.w600, height: 1.2, ls: 0.4, color: n.textMuted),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final n = brightness == Brightness.dark ? NeuTheme.dark : NeuTheme.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: n.accent,
    onPrimary: n.onAccent,
    secondary: n.accent,
    onSecondary: n.onAccent,
    error: n.loss,
    onError: n.isDark ? const Color(0xFF2A0A0A) : Colors.white,
    surface: n.surface,
    onSurface: n.text,
    surfaceContainerHighest: n.surfaceAlt,
    onSurfaceVariant: n.textMuted,
    outline: n.outline,
    outlineVariant: n.outline,
    shadow: n.shadow,
    scrim: Colors.black,
  );
  final tt = _textTheme(n);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: n.surface,
    canvasColor: n.surface,
    fontFamily: _fontFamily,
    textTheme: tt,
    extensions: [n],
    visualDensity: VisualDensity.standard,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(color: n.outline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: n.surface,
      foregroundColor: n.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: tt.titleLarge,
    ),
    iconTheme: IconThemeData(color: n.text, size: 22),
    dialogTheme: DialogThemeData(backgroundColor: n.surface, surfaceTintColor: Colors.transparent),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: n.surface, surfaceTintColor: Colors.transparent),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: n.text, borderRadius: BorderRadius.circular(NeuTheme.radiusS)),
      textStyle: tt.bodySmall?.copyWith(color: n.surface),
      waitDuration: const Duration(milliseconds: 400),
    ),
    focusColor: n.accent.withValues(alpha: 0.2),
    hoverColor: n.accent.withValues(alpha: 0.06),
    scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(n.shadow.withValues(alpha: 0.6))),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: n.text,
      contentTextStyle: tt.bodyMedium?.copyWith(color: n.surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NeuTheme.radiusM)),
    ),
  );
}

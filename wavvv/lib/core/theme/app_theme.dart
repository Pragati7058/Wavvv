import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

class WavvvTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: WavvvColors.wave,
      scaffoldBackgroundColor: WavvvColors.bg,
      cardColor: WavvvColors.bgCard,
      fontFamily: WavvvTypography.fontFamily,
      textTheme: const TextTheme(
        displayLarge: WavvvTypography.heading1,
        headlineMedium: WavvvTypography.heading2,
        titleMedium: WavvvTypography.heading3,
        bodyLarge: WavvvTypography.body,
        bodySmall: WavvvTypography.bodySmall,
        labelLarge: WavvvTypography.label,
      ),
      colorScheme: const ColorScheme.dark(
        surface: WavvvColors.bgCard,
        primary: WavvvColors.wave,
        secondary: WavvvColors.red,
        error: WavvvColors.red,
      ),
      dividerColor: WavvvColors.glassBorder,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: WavvvColors.wave,
        selectionColor: WavvvColors.waveGlow,
        selectionHandleColor: WavvvColors.wave,
      ),
    );
  }
}

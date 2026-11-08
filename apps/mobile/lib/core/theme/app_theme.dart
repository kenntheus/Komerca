import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      textTheme: _textTheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.sandBeige,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.sandBeige,
          foregroundColor: AppColors.primaryGreen,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primaryGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.divider),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sandBeige,
        selectedColor: AppColors.primaryGreen,
        labelStyle: const TextStyle(fontSize: 13),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  // ── ColorScheme ────────────────────────────────────────────────────────────
  // Built explicitly from brand colors — do NOT use ColorScheme.fromSeed.

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary: Forest Green
    primary: AppColors.primaryGreen,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFF4A7A5A), // mid green for containers
    onPrimaryContainer: AppColors.white,

    // Secondary: Sand Beige
    secondary: AppColors.sandBeige,
    onSecondary: AppColors.primaryGreen,
    secondaryContainer: AppColors.sandBeige,
    onSecondaryContainer: AppColors.primaryGreen,

    // Tertiary: teal (matches LOW risk badge; reused for positive accents)
    tertiary: AppColors.riskLowFg,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.riskLowBg,
    onTertiaryContainer: AppColors.riskLowFg,

    // Error: red (matches HIGH risk badge)
    error: AppColors.riskHighFg,
    onError: AppColors.white,
    errorContainer: AppColors.riskHighBg,
    onErrorContainer: AppColors.riskHighFg,

    // Surface
    surface: AppColors.pageBackground,
    onSurface: AppColors.bodyText,
    onSurfaceVariant: AppColors.secondaryText,

    // Outline / dividers
    outline: AppColors.divider,
    outlineVariant: AppColors.divider,

    // Inverse
    inverseSurface: AppColors.bodyText,
    onInverseSurface: AppColors.pageBackground,
    inversePrimary: AppColors.sandBeige,

    shadow: AppColors.bodyText,
    scrim: AppColors.bodyText,
  );

  // ── Text theme ─────────────────────────────────────────────────────────────
  // Uses Inter via google_fonts. Scale: xs=11 sm=13 md=15 lg=17 xl=20 2xl=24 3xl=30.

  static TextTheme get _textTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.bodyText),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.bodyText),
          displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          headlineMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          headlineSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.bodyText),
          titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.bodyText),
          bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.bodyText),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.bodyText),
          bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.secondaryText),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.bodyText),
          labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.secondaryText),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary emerald palette
  static const primary = Color(0xFF006C49);
  static const primaryContainer = Color(0xFF10B981);
  static const onPrimary = Color(0xFFFFFFFF);
  static const inversePrimary = Color(0xFF4EDEA3);

  // Secondary amber palette
  static const secondary = Color(0xFF855300);
  static const secondaryContainer = Color(0xFFFEA619);
  static const secondaryFixedDim = Color(0xFFFFB95F);

  // Tertiary red palette
  static const tertiary = Color(0xFFB91A24);
  static const errorContainer = Color(0xFFFFDAD6);

  // Surface hierarchy
  static const surface = Color(0xFFF8F9FB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F6);
  static const surfaceContainer = Color(0xFFEDEEF0);
  static const surfaceContainerHigh = Color(0xFFE7E8EA);
  static const surfaceContainerHighest = Color(0xFFE1E2E4);
  static const surfaceDim = Color(0xFFD9DADC);

  // Text
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF3C4A42);
  static const outline = Color(0xFF6C7A71);
  static const outlineVariant = Color(0xFFBBCABF);
}

class AppTheme {
  static TextTheme _buildTextTheme() {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.onSurface,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: AppColors.onSurface,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.onSurface,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.onSurface,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  static ThemeData get light {
    final textTheme = _buildTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        errorContainer: AppColors.errorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inversePrimary: AppColors.inversePrimary,
      ),
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: false),
      );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskMateColors {
  // Brand Greens
  static const Color primary = Color(0xFF2D5335);
  static const Color primaryContainer = Color(0xFF456B4B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFBFEAC2);
  static const Color primaryFixed = Color(0xFFC2EDC5);
  static const Color primaryFixedDim = Color(0xFFA7D1AA);

  // Sage / Secondary
  static const Color secondary = Color(0xFF4B6546);
  static const Color secondaryContainer = Color(0xFFCDEBC4);
  static const Color onSecondaryContainer = Color(0xFF516B4C);

  // Tertiary / Amber Accents
  static const Color tertiary = Color(0xFF654500);
  static const Color tertiaryContainer = Color(0xFF845B00);
  static const Color tertiaryFixed = Color(0xFFFFDEAD);
  static const Color tertiaryFixedDim = Color(0xFFFABC4D);
  static const Color amber = Color(0xFFE5A93C);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF0FDF1);
  static const Color surface = Color(0xFFF0FDF1);
  static const Color surfaceLow = Color(0xFFEAF7EC);
  static const Color surfaceContainer = Color(0xFFE4F1E6);
  static const Color surfaceHigh = Color(0xFFDFEBE0);
  static const Color surfaceHighest = Color(0xFFD9E6DB);
  static const Color surfaceContainerHigh = Color(0xFFDFEBE0);
  static const Color surfaceContainerHighest = Color(0xFFD9E6DB);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Text & Typography
  static const Color onSurface = Color(0xFF131E17);
  static const Color onSurfaceVariant = Color(0xFF5C6B5E);
  static const Color outline = Color(0xFF727971);
  static const Color outlineVariant = Color(0xFFE2E8E0);

  // Status semantic pairs
  static const Color statusPendingText = Color(0xFFE5A93C);
  static const Color statusPendingBg = Color(0xFFFDF6EA);

  static const Color statusInProgressText = Color(0xFF4A80B8);
  static const Color statusInProgressBg = Color(0xFFEDF4FA);

  static const Color statusCompletedText = Color(0xFF456B4B);
  static const Color statusCompletedBg = Color(0xFFEFF5F0);

  static const Color statusOverdueText = Color(0xFFE05656);
  static const Color statusOverdueBg = Color(0xFFFDF1F1);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
}

class TaskMateTheme {
  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: TaskMateColors.onSurface,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: TaskMateColors.onSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: TaskMateColors.onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: TaskMateColors.onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: TaskMateColors.onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: TaskMateColors.onSurface,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: TaskMateColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: TaskMateColors.onSurface,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: TaskMateColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: TaskMateColors.onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: TaskMateColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: TaskMateColors.primary,
        onPrimary: TaskMateColors.onPrimary,
        primaryContainer: TaskMateColors.primaryContainer,
        onPrimaryContainer: TaskMateColors.onPrimaryContainer,
        secondary: TaskMateColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: TaskMateColors.secondaryContainer,
        onSecondaryContainer: TaskMateColors.onSecondaryContainer,
        tertiary: TaskMateColors.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: TaskMateColors.tertiaryContainer,
        onTertiaryContainer: Color(0xFFFFDAA3),
        error: TaskMateColors.error,
        onError: Colors.white,
        errorContainer: TaskMateColors.errorContainer,
        onErrorContainer: Color(0xFF93000A),
        surface: TaskMateColors.surface,
        onSurface: TaskMateColors.onSurface,
        surfaceContainerHighest: TaskMateColors.surfaceContainer,
        outline: TaskMateColors.outline,
        outlineVariant: TaskMateColors.outlineVariant,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: TaskMateColors.surface.withValues(alpha: 0.95),
        foregroundColor: TaskMateColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: TaskMateColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: TaskMateColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: TaskMateColors.outlineVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TaskMateColors.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: TaskMateColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: TaskMateColors.outline,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TaskMateColors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TaskMateColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
    );
  }
}

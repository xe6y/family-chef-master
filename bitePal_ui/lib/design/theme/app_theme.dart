import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // 1. Color Palette (Healing Morandi)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF8DA399); // Sage Green
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF0EBE3); // Oatmeal
  static const Color tertiary = Color(0xFFE69B85); // Persimmon
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFDCD7CD);
  static const Color error = Color(0xFFD67D7D);
  static const Color textPrimary = Color(0xFF4A4F50);
  static const Color textSecondary = Color(0xFF8C8F90);

  // ---------------------------------------------------------------------------
  // 2. Text Theme
  // ---------------------------------------------------------------------------
  static TextTheme get _textTheme {
    // Base text style using Noto Sans SC (for Chinese support)
    // Note: Noto Sans SC needs to be loaded via google_fonts
    final baseTextTheme = GoogleFonts.notoSansScTextTheme();
    // Headings/Numbers using Nunito for roundness
    final headingTextTheme = GoogleFonts.nunitoTextTheme();

    return baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: headingTextTheme.displayMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: headingTextTheme.displaySmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: headingTextTheme.headlineLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: headingTextTheme.headlineSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: textPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: textPrimary,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: textSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        color: textSecondary,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        color: textSecondary,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Theme Data
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: textPrimary,
        tertiary: tertiary,
        onTertiary: Colors.white,
        error: error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: outline,
      ),
      scaffoldBackgroundColor: secondary,
      textTheme: _textTheme,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent, 
        indicatorColor: primary.withOpacity(0.3),
        labelTextStyle: MaterialStateProperty.all(
          _textTheme.labelSmall?.copyWith(
             color: textPrimary,
             fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
           if (states.contains(MaterialState.selected)) {
             return const IconThemeData(color: textPrimary);
           }
           return const IconThemeData(color: textSecondary);
        }),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: outline, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: const BorderSide(color: outline),
        shape: const StadiumBorder(),
        labelStyle: _textTheme.labelMedium,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        surface: const Color(0xFF1A1C1E),
        onSurface: Colors.white70,
      ),
      scaffoldBackgroundColor: const Color(0xFF111315),
      textTheme: _textTheme.apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}

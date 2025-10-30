import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Zen Palette - спокойные, натуральные цвета
  static const _primary = Color(0xFF6B9080); // Sage green - спокойный, природный
  static const _accent = Color(0xFFA4C3B2);  // Soft mint
  static const _background = Color(0xFF0A0E12); // Deep charcoal
  static const _surface = Color(0xFF151920);    // Slightly lighter
  static const _surfaceLight = Color(0xFF1E2329); // Card background

  // Text
  static const _textPrimary = Color(0xFFEAF4F4);   // Soft white
  static const _textSecondary = Color(0xFF8B9A9A); // Muted sage gray
  static const _textTertiary = Color(0xFF5A6565);  // Subtle gray

  // Macros - earthy, muted tones
  static const _proteinColor = Color(0xFF7FB3D5); // Soft blue
  static const _carbColor = Color(0xFFE8B86D);    // Warm sand
  static const _fatColor = Color(0xFFD4A5A5);     // Dusty rose

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.outfitTextTheme(const TextTheme(
      displayLarge: TextStyle(color: _textPrimary, fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: -1.5),
      displayMedium: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -0.5),
      displaySmall: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w500),
      titleLarge: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: _textTertiary, fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelMedium: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: TextStyle(color: _textTertiary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.dark(
        primary: _primary,
        secondary: _accent,
        surface: _surface,
        background: _background,
        error: const Color(0xFFCF6679),
        onPrimary: _background,
        onSurface: _textPrimary,
        onBackground: _textPrimary,
        tertiary: _carbColor,
        primaryContainer: _proteinColor,
        secondaryContainer: _fatColor,
        surfaceVariant: _surfaceLight,
        outline: _textTertiary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: _textSecondary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: _surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _textTertiary.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        hintStyle: TextStyle(color: _textTertiary, fontSize: 14),
        labelStyle: const TextStyle(color: _textSecondary),
        prefixIconColor: _textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: _textTertiary.withOpacity(0.1),
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceLight,
        contentTextStyle: const TextStyle(color: _textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Light theme (placeholder - можешь развить позже)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _primary,
      ),
    );
  }
}
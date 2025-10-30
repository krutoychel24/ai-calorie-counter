import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main Palette
  static const _primary = Color(0xFF38BDF8); // Calming Sky Blue
  static const _background = Color(0xFF121826); // Soft, dark slate
  static const _surface = Color(0xFF1A2130);   // Slightly lighter surface
  static const _border = Color(0xFF4B5563);     // Softer border

  // Text
  static const _textPrimary = Color(0xFFE5E7EB);   // Off-white
  static const _textSecondary = Color(0xFF9CA3AF); // Muted gray

  // Semantic Colors
  static const _proteinColor = Color(0xFF34D399); // Emerald
  static const _carbColor = Color(0xFFFBBF24);   // Amber
  static const _fatColor = Color(0xFFF87171);     // Red
  static const _error = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(const TextTheme(
      displayLarge: TextStyle(color: _textPrimary, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: TextStyle(color: _textPrimary, fontSize: 28, fontWeight: FontWeight.w600),
      displaySmall: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      labelMedium: TextStyle(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      labelSmall: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.dark(
        primary: _primary,
        secondary: _textSecondary,
        surface: _surface,
        background: _background,
        error: _error,
        onPrimary: _background,
        onSurface: _textPrimary,
        onBackground: _textPrimary,
        onSecondary: _textPrimary,
        tertiary: _carbColor,
        onTertiary: _background,
        primaryContainer: _proteinColor,
        onPrimaryContainer: _background,
        secondaryContainer: _fatColor,
        onSecondaryContainer: _textPrimary,
        surfaceVariant: _surface,
        outline: _border,
        outlineVariant: _border.withOpacity(0.5),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: const IconThemeData(color: _textSecondary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _border.withOpacity(0.2), width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.black, // Black for better contrast on sky blue
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          side: BorderSide(color: _border.withOpacity(0.4)),
          foregroundColor: _textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface, // Use surface color
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: _textSecondary),
        prefixIconColor: _textSecondary,
      ),
      dividerTheme: DividerThemeData(
        color: _border.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _primary,
        linearTrackColor: _surface,
        circularTrackColor: _surface,
      ),
                  snackBarTheme: SnackBarThemeData(
                     backgroundColor: _surface,
                     contentTextStyle: const TextStyle(color: _textPrimary),
                     actionTextColor: _primary,
                     behavior: SnackBarBehavior.floating,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     elevation: 4,
                  ),
            
                  popupMenuTheme: PopupMenuThemeData(
                    color: _surface,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: textTheme.bodyLarge,
                  ),
                );
              }  // Placeholder for light theme
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
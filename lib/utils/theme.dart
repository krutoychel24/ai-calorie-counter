import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF2DD4BF);
  static const _primaryLight = Color(0xFF5EEAD4);
  static const _background = Color(0xFF060910);
  static const _surface = Color(0xFF111827);
  static const _surfaceLight = Color(0xFF1F2937);
  static const _textPrimary = Color(0xFFF9FAFB);
  static const _textSecondary = Color(0xFF9CA3AF);
  static const _border = Color(0xFF374151);

  static const _mealAccent1 = Color(0xFF3B82F6);
  static const _mealAccent2 = Color(0xFF10B981);
  static const _mealAccent3 = Color(0xFFF59E0B);
  static const _mealAccent4 = Color(0xFF8B5CF6);

  static const _proteinColor = Color(0xFF34D399);
  static const _carbColor = Color(0xFFFACC15);
  static const _fatColor = Color(0xFFF87171);

  static const _error = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,

      // --- REMOVED 'const' HERE ---
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
        surfaceVariant: _surfaceLight,
        outline: _border,
        outlineVariant: _border.withOpacity(0.5), // This line now works
        tertiaryContainer: _mealAccent1,
        onTertiaryContainer: _textPrimary,
        surfaceTint: _mealAccent2,
        inverseSurface: _mealAccent3,
        onInverseSurface: _textPrimary,
        inversePrimary: _mealAccent4,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: _textSecondary, size: 22),
      ),

      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border.withOpacity(0.3), width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _textSecondary,
          backgroundColor: Colors.transparent,
          highlightColor: _surfaceLight.withOpacity(0.5),
        ),
      ),

       outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          side: BorderSide(color: _border.withOpacity(0.5)),
          foregroundColor: _textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w400),
        labelStyle: const TextStyle(color: _textSecondary),
         prefixIconColor: _textSecondary,
      ),

      textTheme: const TextTheme(
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
      ),

      dividerTheme: DividerThemeData(
        color: _border.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: const ListTileThemeData(
         dense: true,
         visualDensity: VisualDensity.compact,
         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
         titleTextStyle: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w400),
         subtitleTextStyle: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
         leadingAndTrailingTextStyle: TextStyle(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
         color: _primary,
         linearTrackColor: _surfaceLight,
         circularTrackColor: _surfaceLight,
      ),

      snackBarTheme: SnackBarThemeData(
         backgroundColor: _surfaceLight,
         contentTextStyle: const TextStyle(color: _textPrimary),
         actionTextColor: _primary,
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
         elevation: 4,
      ),
    );
  }

  static ThemeData get lightTheme {
     return ThemeData(
       useMaterial3: true,
       brightness: Brightness.light,
       colorScheme: const ColorScheme.light(
         primary: _primary,
         secondary: _primaryLight,
       ),
     );
  }
}
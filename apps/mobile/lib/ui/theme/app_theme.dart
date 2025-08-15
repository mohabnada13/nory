import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette based on the new design
class AppPalette {
  // Background colors
  static const bgTop = Color(0xFFFFE3ED);
  static const bgMid = Color(0xFFF7C7E3);
  static const bgTransparent = Colors.transparent;
  
  // Primary gradient colors
  static const primaryStart = Color(0xFF7B61FF);
  static const primaryEnd = Color(0xFFA15CFF);
  
  // Accent colors
  static const accentLilac = Color(0xFFEFE8FF);
  static const shadowPink = Color(0xFFE9CFEA);
  
  // Text colors
  static const textPrimary = Color(0xFF1D1B20);
  static const textSecondary = Color(0xFF5C5966);
  
  // Base colors
  static const white = Colors.white;
  
  // Gradients
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMid, bgTransparent],
  );
  
  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryStart, primaryEnd],
  );
}

/// App theme configuration
class AppTheme {
  /// Light theme configuration
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppPalette.primaryStart,
      secondary: AppPalette.primaryEnd,
      background: AppPalette.bgTransparent,
      surface: AppPalette.white,
      error: Colors.redAccent,
      onPrimary: AppPalette.white,
      onSecondary: AppPalette.white,
      onBackground: AppPalette.textPrimary,
      onSurface: AppPalette.textPrimary,
    ),
    scaffoldBackgroundColor: AppPalette.bgTransparent,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: const TextStyle(color: AppPalette.textPrimary),
      displayMedium: const TextStyle(color: AppPalette.textPrimary),
      displaySmall: const TextStyle(color: AppPalette.textPrimary),
      headlineLarge: const TextStyle(color: AppPalette.textPrimary),
      headlineMedium: const TextStyle(color: AppPalette.textPrimary),
      headlineSmall: const TextStyle(color: AppPalette.textPrimary),
      titleLarge: const TextStyle(color: AppPalette.textPrimary),
      titleMedium: const TextStyle(color: AppPalette.textPrimary),
      titleSmall: const TextStyle(color: AppPalette.textPrimary),
      bodyLarge: const TextStyle(color: AppPalette.textPrimary),
      bodyMedium: const TextStyle(color: AppPalette.textPrimary),
      bodySmall: const TextStyle(color: AppPalette.textSecondary),
      labelLarge: const TextStyle(color: AppPalette.textPrimary),
      labelMedium: const TextStyle(color: AppPalette.textPrimary),
      labelSmall: const TextStyle(color: AppPalette.textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.bgTransparent,
      foregroundColor: AppPalette.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.primaryStart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.primaryStart,
        side: const BorderSide(color: AppPalette.primaryStart),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.white.withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppPalette.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPalette.primaryStart),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    cardTheme: CardTheme(
      color: AppPalette.white.withOpacity(0.7),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
  
  /// Glass effect decoration
  static BoxDecoration glassDecoration(double radius) {
    return BoxDecoration(
      color: AppPalette.white.withOpacity(0.25),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppPalette.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppPalette.shadowPink.withOpacity(0.15),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }
}

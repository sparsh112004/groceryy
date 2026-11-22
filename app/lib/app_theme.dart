import 'package:flutter/material.dart';

/// Application theme definitions following Material 3 guidelines.
/// Primary color: calm teal.
/// Status colors: green (fresh), amber (soon), red (expired).
/// All body text sizes are >= 16sp as required by SPEC Section 8.
class AppTheme {
  // Brand & Primary Colors (Calm Deep Teal)
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryTealLight = Color(0xFF14B8A6);
  static const Color primaryTealContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF115E59);

  // Expiry Status Semantic Colors
  static const Color statusFresh = Color(0xFF2E7D32); // Green
  static const Color statusFreshContainer = Color(0xFFE8F5E9);
  static const Color statusSoon = Color(0xFFE65100); // Amber / Orange
  static const Color statusSoonContainer = Color(0xFFFFF3E0);
  static const Color statusExpired = Color(0xFFC62828); // Red
  static const Color statusExpiredContainer = Color(0xFFFFEBEE);

  // Background & Surface
  static const Color surfaceLight = Color(0xFFFBFDFA);
  static const Color backgroundLight = Color(0xFFF4F6F4);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        primaryContainer: primaryTealContainer,
        onPrimaryContainer: onPrimaryContainer,
        surface: surfaceLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      // Typography enforcing body text at least 16sp (SPEC Section 8)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        headlineMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleMedium: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
        bodyLarge: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.normal,
          color: Color(0xFF1F2937),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: Color(0xFF374151),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 16.0, // Minimum 16sp per specification
          fontWeight: FontWeight.normal,
          color: Color(0xFF6B7280),
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Minimum tap target size 48x48dp (SPEC Section 8)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryTealContainer,
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: primaryTeal,
            );
          }
          return const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.normal,
            color: Color(0xFF6B7280),
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        color: Colors.white,
      ),
    );
  }
}

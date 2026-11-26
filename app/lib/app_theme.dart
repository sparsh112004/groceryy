import 'package:flutter/material.dart';

/// Application theme definitions with an eye-soothing forest-green & sage-cream palette.
class AppTheme {
  // Brand & Primary Colors (Soothing Forest Green & Soft Mint)
  static const Color primaryGreen = Color(0xFF1B6B3A);
  static const Color primaryGreenDark = Color(0xFF14522C);
  static const Color primaryGreenLight = Color(0xFF2D8A52);
  static const Color primaryContainer = Color(0xFFD8F0E1);
  static const Color onPrimaryContainer = Color(0xFF14522C);

  // Backwards-compatible aliases
  static const Color primaryTeal = primaryGreen;
  static const Color primaryTealLight = primaryGreenLight;
  static const Color primaryTealContainer = primaryContainer;

  // Expiry Status Semantic Colors
  static const Color statusFresh = Color(0xFF1E7E34);
  static const Color statusFreshContainer = Color(0xFFE6F4EA);
  static const Color statusSoon = Color(0xFFC26A00);
  static const Color statusSoonContainer = Color(0xFFFFF4E0);
  static const Color statusExpired = Color(0xFFC62828);
  static const Color statusExpiredContainer = Color(0xFFFDECEC);

  // Background, Surface & Borders
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF6F8F5);
  static const Color softMintTint = Color(0xFFEAF5EE);
  static const Color borderSubtle = Color(0xFFE4EAE5);
  static const Color textPrimary = Color(0xFF17231C);
  static const Color textSecondary = Color(0xFF5F6D64);

  /// Standard soft-shadow white card decoration used across screens.
  static BoxDecoration cardDecoration({
    Color color = surfaceLight,
    double radius = 18,
    Color borderColor = borderSubtle,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x090F291A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        surface: surfaceLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30.0,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: Color(0xFF37443C),
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: primaryGreen,
          side: const BorderSide(color: Color(0xFFBBD3C2), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        indicatorColor: primaryContainer,
        elevation: 6,
        shadowColor: const Color(0x14000000),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryGreen, size: 24);
          }
          return const IconThemeData(color: Color(0xFF6B7870), size: 23);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
            );
          }
          return const TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7870),
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        color: Colors.white,
      ),
    );
  }
}

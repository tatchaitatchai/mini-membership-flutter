import 'package:flutter/material.dart';

class POSTheme {
  // Primary accent — single confident indigo
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF2FF);

  // Semantic colors — muted, not garish
  static const Color successColor = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warningColor = Color(0xFFCA8A04);
  static const Color warningLight = Color(0xFFFEFCE8);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color infoColor = Color(0xFF2563EB);
  static const Color purpleColor = Color(0xFF7C3AED);
  static const Color orangeColor = Color(0xFFEA580C);
  static const Color tealColor = Color(0xFF0D9488);
  static const Color roseColor = Color(0xFFE11D48);

  // Surfaces — clean neutral slate
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color mutedText = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: successColor,
        surface: surfaceColor,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: const BorderSide(color: borderColor, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: dangerColor, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: Color(0xFF0F172A),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: Color(0xFF374151)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1, space: 1),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(0xFF334155), fontSize: 15),
        bodyMedium: TextStyle(color: Color(0xFF475569), fontSize: 14),
        bodySmall: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        labelLarge: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // static const Color navy = Color(0xFF093747);
  // static const Color lightNavy = Color(0xFF1B5569);
  // static const Color navy = Color(0xFF2EB0A2);
  // static const Color lightNavy = Color(0xFF1B5569);
  static const Color navy = Color(0xFF489FF7);
  static const Color lightNavy = Color(0xFF4166FA);
  static const Color appBackground = Color(0xFFF4F6FA);
  static const Color cardBackground = Colors.white;
  static const String fontFamily = 'Inter';

  /// Text scale for the whole app: nudged up on wider screens, never driven by
  /// the OS font size setting. 390 is the logical width the UI was designed at.
  static double textScale(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    return (shortestSide / 390).clamp(1.0, 1.1);
  }

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: lightNavy,
      surface: cardBackground,
      brightness: Brightness.light,
    );

    final textTheme = ThemeData(brightness: Brightness.light).textTheme.apply(
      fontFamily: fontFamily,
      bodyColor: const Color(0xFF0F172A),
      displayColor: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actionsIconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

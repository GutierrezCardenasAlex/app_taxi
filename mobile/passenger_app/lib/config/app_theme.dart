import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build() {
    const surface = Color(0xFFF7F2E8);
    const ink = Color(0xFF122117);
    const accent = Color(0xFF1FA35B);
    const sunset = Color(0xFFF4A422);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: sunset,
        surface: surface,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.05,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF33443A),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
    );
  }
}


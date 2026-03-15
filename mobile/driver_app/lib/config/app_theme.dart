import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF3EEE2),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF4A422),
        primary: const Color(0xFFF4A422),
        secondary: const Color(0xFF1E88E5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

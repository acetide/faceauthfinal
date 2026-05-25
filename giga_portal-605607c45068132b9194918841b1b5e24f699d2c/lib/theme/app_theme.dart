import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF424094);
  static const Color accent = Color(0xFF7C78E6);
  static const Color background = Color(0xFFF6F7FB);

  static ThemeData lightTheme() {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, surface: background),
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
        titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
        bodyLarge: const TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.black87),
        bodySmall: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      iconTheme: const IconThemeData(color: primary),
    );
  }
}

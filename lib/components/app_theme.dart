import 'package:flutter/material.dart';

class AppTheme {
  // ================= LIGHT THEME =================
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F5D2F), // olive green (from logo)
      brightness: Brightness.light,
      background: const Color(0xFFF7F3EC), // cream
      surface: const Color(0xFFFDFBF7),    // lighter cream
    ),

    scaffoldBackgroundColor: const Color(0xFFF7F3EC), // cream background

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF8A9B4C),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF4F5D2F),
      textColor: Color(0xFF2E2E2E),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE9EEDC), // very light green/cream mix
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFFFDFBF7),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF7A8F3A), // softer green accent
      foregroundColor: Colors.white,
    ),
  );

  // ================= DARK THEME =================
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor: const Color(0xFF0D1B2A),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B263B),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Colors.lightBlueAccent,
      textColor: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1B263B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

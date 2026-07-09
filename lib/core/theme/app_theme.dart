import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    const seedColor = Color(0xFFD97706);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardColor: const Color(0xFF111C33),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF0B1324),
        foregroundColor: Colors.white,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF0B1324),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF111827),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      fontFamily: 'Segoe UI',
    );
  }
}

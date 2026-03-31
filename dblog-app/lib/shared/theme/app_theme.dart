import 'package:flutter/material.dart';

/// Tema visual de la aplicación dBLog.
class AppTheme {
  AppTheme._();

  // -- Colores principales --
  static const Color primary = Color(0xFF1E88E5);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  // -- Colores de nivel de dB --
  static const Color levelQuiet = Color(0xFF4CAF50);
  static const Color levelModerate = Color(0xFFFFEB3B);
  static const Color levelLoud = Color(0xFFFF9800);
  static const Color levelDangerous = Color(0xFFF44336);

  // -- Colores de gráfica --
  static const Color chartLine = Color(0xFF42A5F5);
  static const Color chartGradientTop = Color(0x4042A5F5);
  static const Color chartGradientBottom = Color(0x0042A5F5);

  /// Retorna el color correspondiente al nivel de dB.
  static Color colorForDb(double db) {
    if (db < 50) return levelQuiet;
    if (db < 70) return levelModerate;
    if (db < 85) return levelLoud;
    return levelDangerous;
  }

  /// ThemeData principal (oscuro).
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 72,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Tema visual de la aplicación dBLog.
class AppTheme {
  AppTheme._();

  // -- Colores principales --
  static const Color primary = Color(0xFF00D4AA);
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF16213E);
  static const Color surfaceLight = Color(0xFF1F2F50);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892B0);

  // -- Colores de acento --
  static const Color accent = Color(0xFF00D4AA);
  static const Color danger = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFA502);
  static const Color success = Color(0xFF00D4AA);

  // -- Colores de nivel de dB --
  static const Color levelQuiet = Color(0xFF00D4AA);
  static const Color levelModerate = Color(0xFFFFA502);
  static const Color levelLoud = Color(0xFFFF6348);
  static const Color levelDangerous = Color(0xFFFF4757);

  // -- Colores de gráfica --
  static const Color chartLine = Color(0xFF00D4AA);
  static const Color chartGradientTop = Color(0x4000D4AA);
  static const Color chartGradientBottom = Color(0x0000D4AA);
  static const Color chartLegalLimit = Color(0xFFFF4757);

  // -- Constantes de diseño --
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;

  /// Retorna el color correspondiente al nivel de dB.
  static Color colorForDb(double db) {
    if (db < 50) return levelQuiet;
    if (db < 70) return levelModerate;
    if (db < 85) return levelLoud;
    return levelDangerous;
  }

  /// Retorna la etiqueta descriptiva del nivel de dB.
  static String labelForDb(double db) {
    if (db < 40) return 'Silencio';
    if (db < 50) return 'Tranquilo';
    if (db < 60) return 'Moderado';
    if (db < 70) return 'Conversación';
    if (db < 80) return 'Tráfico';
    if (db < 85) return 'Ruidoso';
    if (db < 100) return 'Peligroso';
    return 'Muy peligroso';
  }

  /// ThemeData principal (oscuro).
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        surface: surface,
        onPrimary: background,
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: surfaceLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

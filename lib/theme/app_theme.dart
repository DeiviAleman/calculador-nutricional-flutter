import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales de marca (Salud y Nutrición)
  static const Color primaryEmerald = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color mutedSlate = Color(0xFF64748B);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Colores Modo Oscuro
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkCardBackground = Color(0xFF1E293B);
  static const Color darkBorderColor = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Colores semánticos para Macronutrientes y Calorías
  static const Color caloriesColor = Color(0xFFF97316); // Naranja Energía
  static const Color proteinColor = Color(0xFF3B82F6); // Azul Proteína
  static const Color carbsColor = Color(0xFFF59E0B); // Ámbar Carbohidratos
  static const Color fatColor = Color(0xFFEC4899); // Rosa/Coral Grasas

  // Colores para rangos de IMC
  static const Color bmiUnderweight = Color(0xFF38BDF8);
  static const Color bmiNormal = Color(0xFF10B981);
  static const Color bmiOverweight = Color(0xFFF59E0B);
  static const Color bmiObese = Color(0xFFEF4444);

  // Helpers adaptativos según el tema activo (Claro u Oscuro)
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : darkSlate;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : mutedSlate;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? darkCardBackground : cardBackground;

  static Color subtleBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F172A) : backgroundLight;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorderColor : const Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        brightness: Brightness.light,
        primary: primaryEmerald,
        secondary: caloriesColor,
        surface: cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: darkSlate,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkSlate,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        brightness: Brightness.dark,
        primary: primaryEmerald,
        secondary: caloriesColor,
        surface: darkCardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

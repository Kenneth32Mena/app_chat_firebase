import 'package:flutter/material.dart';

class AppTheme {
  // Colores Ártico
  static const Color arcticBlue = Color(0xFF0284C7); // Azul Ártico Principal
  static const Color arcticLight = Color(0xFF38BDF8); // Azul Glaciar Claro
  static const Color arcticDark = Color(0xFF0369A1); // Azul Profundo Ártico
  static const Color iceFrostLight = Color(0xFFE0F2FE); // Escarcha Clara
  static const Color iceFrostDark = Color(0xFF0F172A); // Noche Ártica Profunda

  // Burbujas de chat
  static const Color lightBubbleOwn = Color(0xFFBAE6FD); // Azul Hielo Suave
  static const Color lightBubbleOther = Colors.white;
  static const Color darkBubbleOwn = Color(0xFF0369A1); // Azul Profundo
  static const Color darkBubbleOther = Color(0xFF1E293B); // Pizarra Oscura

  // Tema Claro (Arctic White & Blue)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: arcticBlue,
      onPrimary: Colors.white,
      primaryContainer: iceFrostLight,
      onPrimaryContainer: arcticDark,
      secondary: arcticLight,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F9FF), // Blanco Ártico / Nieve
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: arcticBlue,
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: arcticBlue,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: arcticBlue, width: 2.0),
      ),
    ),
  );

  // Tema Oscuro (Arctic Deep Night & Sky)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: arcticLight,
      onPrimary: Color(0xFF0F172A),
      primaryContainer: arcticDark,
      onPrimaryContainer: Colors.white,
      secondary: arcticBlue,
      onSecondary: Colors.white,
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: iceFrostDark, // Noche Glacial
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: arcticLight,
        foregroundColor: Color(0xFF0F172A),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: arcticLight, width: 2.0),
      ),
    ),
  );
}

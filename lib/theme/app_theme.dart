import 'package:flutter/material.dart';
import '../core/constants.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // THÈME SOMBRE (Par défaut)
  // ============================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BnoxColors.dark,
      primaryColor: BnoxColors.violet,
      colorScheme: const ColorScheme.dark(
        primary: BnoxColors.violet,
        secondary: BnoxColors.cyan,
        surface: Color(0xFF0B1020),
        onPrimary: BnoxColors.white,
        onSecondary: BnoxColors.dark,
        onSurface: BnoxColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: BnoxColors.white),
        titleTextStyle: TextStyle(color: BnoxColors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BnoxColors.violet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1020),
        hintStyle: const TextStyle(color: BnoxColors.gray),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A2238))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BnoxColors.cyan, width: 1.5)),
      ),
    );
  }

  // ============================================================
  // THÈME CLAIR
  // ============================================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Fond blanc cassé
      primaryColor: BnoxColors.violet,
      colorScheme: const ColorScheme.light(
        primary: BnoxColors.violet,
        secondary: BnoxColors.cyan,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: BnoxColors.dark,
        onSurface: BnoxColors.dark, // Le texte devient sombre
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: BnoxColors.dark), // Icônes sombres
        titleTextStyle: TextStyle(color: BnoxColors.dark, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BnoxColors.violet,
          foregroundColor: Colors.white, // Les boutons gardent leur texte blanc
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Fond de champ blanc
        hintStyle: const TextStyle(color: Colors.black54),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BnoxColors.cyan, width: 1.5)),
      ),
    );
  }
}
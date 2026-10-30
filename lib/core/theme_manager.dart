import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  ThemeManager._();

  static const String _key = 'app_theme';
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  /// Charge le thème sauvegardé au démarrage
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? true;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Change le thème et le sauvegarde
  static Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }
}
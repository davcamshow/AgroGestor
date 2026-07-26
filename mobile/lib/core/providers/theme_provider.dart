import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = "theme_preference";

  // Cambiamos el estado inicial a "light" en lugar de "system" para evitar el salto nulo
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  bool get isDarkMode => state == ThemeMode.dark;

  Future<void> toggleTheme() async {
    // Si es oscuro, pasa a claro; si no, pasa a oscuro
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, state == ThemeMode.dark);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);

    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }
}

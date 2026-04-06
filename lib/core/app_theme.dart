import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme-mode notifier. Changing this value rebuilds the entire app.
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

const _kDarkKey = 'pref_dark_mode';

/// Load persisted theme from SharedPreferences on app start.
Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(_kDarkKey) ?? false;
  appThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

/// Save dark-mode preference so it survives app restarts.
Future<void> persistTheme(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kDarkKey, isDark);
}

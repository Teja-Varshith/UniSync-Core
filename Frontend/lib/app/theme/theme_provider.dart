import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisync/app/theme/app_theme.dart';

// Enum for theme modes - simplified to only support dark mode
enum AppThemeMode {
  dark,
}

// StateNotifier to manage theme state - now locked to dark
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dark);

  // Methods removed as theme is now fixed to dark
}

// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

// Provider that returns the current ThemeData based on theme mode
// Always returns dark theme
final currentThemeDataProvider = Provider<ThemeData>((ref) {
  return AppTheme.darkTheme;
});

// Provider to get the ThemeMode for MaterialApp
// Always returns dark
final materialThemeModeProvider = Provider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

// Provider to check if current theme is dark
// Always returns true
final isDarkThemeProvider = Provider<bool>((ref) {
  return true;
});

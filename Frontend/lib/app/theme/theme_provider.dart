import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:UniSync/storage/secure_storage.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService(),
        super(ThemeMode.system) {
    _restoreThemeMode();
  }

  final SecureStorageService _secureStorage;

  Future<void> _restoreThemeMode() async {
    final storedMode = await _secureStorage.getThemeMode();
    state = _parseThemeMode(storedMode);
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _secureStorage.setThemeMode(_serializeThemeMode(mode));
  }

  void toggleBetweenLightAndDark() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
      return;
    }
    setThemeMode(ThemeMode.dark);
  }
}

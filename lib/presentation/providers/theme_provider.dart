import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode) with persistence
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;  // Default to system preference
  final SharedPreferences? _prefs;

  ThemeProvider([this._prefs]) {
    _loadThemeFromPreferences();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeToPreferences();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemeToPreferences();
      notifyListeners();
    }
  }

  Future<void> _loadThemeFromPreferences() async {
    if (_prefs == null) return;

    final themeModeString = _prefs!.getString('theme_mode');
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> _saveThemeToPreferences() async {
    await _prefs?.setString('theme_mode', _themeMode.toString());
  }
}

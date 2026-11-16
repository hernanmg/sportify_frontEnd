import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  /// Producto KeepSync: Ink + Volt (oscuro) por defecto.
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notifica a los widgets para que se redibujen
  }
}
import 'package:flutter/material.dart';

/// Permite a pantallas hijas (p. ej. Inicio) cambiar la pestaña del shell.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.selectTab,
    required this.activeTabIndex,
    required super.child,
  });

  final void Function(int index) selectTab;
  /// Índice de la pestaña visible (0=Deportiva, 1=Finanzas, 2=Inicio, 3=Eventos).
  final int activeTabIndex;

  static const int homeTabIndex = 2;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    // Tras hot reload, instancias viejas pueden no tener activeTabIndex.
    try {
      return activeTabIndex != oldWidget.activeTabIndex;
    } catch (_) {
      return true;
    }
  }
}

/// Espacio reservado para la barra inferior del shell (FAB internos).
const double kAppShellBottomInset = 76;

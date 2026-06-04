import 'package:flutter/material.dart';

/// Permite a pantallas hijas (p. ej. Inicio) cambiar la pestaña del shell.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final void Function(int index) selectTab;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) => false;
}

/// Espacio reservado para la barra inferior del shell (FAB internos).
const double kAppShellBottomInset = 76;

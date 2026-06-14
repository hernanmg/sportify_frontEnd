import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:sportify_amateur/features/sports/sports_management_args.dart';

class HelpNavigationAction {
  final String label;
  final String? route;
  final Object? arguments;
  final int? shellTabIndex;

  const HelpNavigationAction({
    required this.label,
    this.route,
    this.arguments,
    this.shellTabIndex,
  });
}

class HelpNavigation {
  HelpNavigation._();

  static const _map = <String, HelpNavigationAction>{
    'inicio': HelpNavigationAction(
      label: 'Ir al inicio',
      shellTabIndex: AppShellScope.homeTabIndex,
    ),
    'unirse-equipo': HelpNavigationAction(
      label: 'Unirme a un equipo',
      route: '/join-team',
    ),
    'plantel': HelpNavigationAction(
      label: 'Ver plantel',
      route: '/sports/roster',
      arguments: SportsManagementArgs(initialTabIndex: 0),
    ),
    'convocatoria': HelpNavigationAction(
      label: 'Ir a convocatorias',
      route: '/sports/roster',
      arguments: SportsManagementArgs(initialTabIndex: 2),
    ),
    'alineacion': HelpNavigationAction(
      label: 'Ir a Mis partidos → Alineación',
      route: '/sports/my-matches',
    ),
    'gestionar-partido': HelpNavigationAction(
      label: 'Mis partidos',
      route: '/sports/my-matches',
    ),
    'eventos': HelpNavigationAction(
      label: 'Ir a Mis eventos',
      shellTabIndex: 3,
    ),
    'calendario': HelpNavigationAction(
      label: 'Abrir calendario',
      route: '/sports/calendar',
    ),
    'finanzas': HelpNavigationAction(
      label: 'Ir a Finanzas',
      shellTabIndex: 1,
    ),
    'panel-equipo': HelpNavigationAction(
      label: 'Panel del equipo',
      route: '/sports/admin-panel',
    ),
    'notificaciones': HelpNavigationAction(
      label: 'Ver notificaciones',
      route: '/notifications',
    ),
    'perfil': HelpNavigationAction(
      label: 'Ir a mi perfil',
      route: '/profile',
    ),
    'roles': HelpNavigationAction(
      label: 'Ver mi perfil',
      route: '/profile',
    ),
    'equipo-config': HelpNavigationAction(
      label: 'Gestión de equipos',
      route: '/teams',
    ),
  };

  static HelpNavigationAction? forArticle(String id) => _map[id];

  static Future<void> go(BuildContext context, HelpNavigationAction action) {
    if (action.shellTabIndex != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppShellScope.maybeOf(context)?.selectTab(action.shellTabIndex!);
      });
      return Future.value();
    }
    if (action.route != null) {
      return Navigator.pushNamed(
        context,
        action.route!,
        arguments: action.arguments,
      );
    }
    return Future.value();
  }
}

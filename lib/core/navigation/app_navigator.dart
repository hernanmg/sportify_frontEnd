import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/sports/sports_management_args.dart';

/// Navegación global (p. ej. al abrir una notificación push).
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get state => key.currentState;

  static void openFromPushData(Map<String, dynamic> data) {
    final nav = state;
    if (nav == null) return;

    final action = data['action']?.toString();
    final deepLink = data['deepLink']?.toString();
    final teamId = int.tryParse('${data['teamId'] ?? ''}');

    if (action == 'convocation_response') {
      nav.pushNamed('/notifications');
      return;
    }

    if (action == 'open_player_status' || deepLink == '/sports/roster') {
      nav.pushNamed(
        '/sports/roster',
        arguments: SportsManagementArgs.playerStatus(teamId: teamId),
      );
      return;
    }

    nav.pushNamed('/notifications');
  }
}

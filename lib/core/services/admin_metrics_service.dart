import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';

class AdminMetricsService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> getDashboardMetrics(
      {String userRole = 'player'}) async {
    try {
      final response = await _dio.get('/admin/metrics', queryParameters: {
        'context': userRole, // Enviamos el rol para contexto específico
      });
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('Error al obtener métricas');
    } catch (e) {
      // Si el endpoint no existe aún, retornamos datos mock
      return _getMockMetrics(userRole: userRole);
    }
  }

  Map<String, dynamic> _getMockMetrics({String userRole = 'player'}) {
    // Métricas específicas según el rol del usuario
    switch (userRole) {
      case 'player':
        return _getPlayerMetrics();
      case 'team_captain':
        return _getTeamCaptainMetrics();
      case 'manager':
      case 'super_admin':
        return _getManagerMetrics();
      default:
        return _getPlayerMetrics();
    }
  }

  // Métricas específicas para JUGADORES - SUS estadísticas personales
  Map<String, dynamic> _getPlayerMetrics() {
    return {
      'personal_stats': {
        'matches_played': 12,
        'goals_scored': 8,
        'assists': 5,
        'yellow_cards': 2,
        'red_cards': 0,
        'minutes_played': 1080,
        'average_rating': 7.8,
      },
      'team_context': {
        'team_name': 'Leones FC',
        'team_position': 3,
        'next_match': 'vs Águilas - Dom 15:00',
        'teammates_count': 22,
      },
      'recent_matches': [
        {
          'date': '2024-01-15',
          'opponent': 'Tigres FC',
          'result': '2-1 Victoria',
          'my_goals': 1,
          'my_assists': 0,
          'my_rating': 8.5,
          'minutes': 90,
        },
        {
          'date': '2024-01-08',
          'opponent': 'Águilas FC',
          'result': '1-1 Empate',
          'my_goals': 0,
          'my_assists': 1,
          'my_rating': 7.2,
          'minutes': 78,
        },
        {
          'date': '2024-01-01',
          'opponent': 'Halcones FC',
          'result': '3-0 Victoria',
          'my_goals': 2,
          'my_assists': 0,
          'my_rating': 9.0,
          'minutes': 90,
        },
      ],
      'achievements': [
        {
          'title': 'Goleador del Mes',
          'description': '8 goles en Enero',
          'icon': 'sports_soccer',
          'color': 'gold',
        },
        {
          'title': 'Mejor Rating',
          'description': '9.0 vs Halcones FC',
          'icon': 'star',
          'color': 'blue',
        },
      ],
      'recentActivity': [
        {
          'type': 'goal_scored',
          'message': 'Gol anotado en victoria vs Tigres FC',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'icon': 'sports_soccer',
          'color': 'green',
        },
        {
          'type': 'assist',
          'message': 'Asistencia en empate vs Águilas FC',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 9))
              .toIso8601String(),
          'icon': 'handshake',
          'color': 'blue',
        },
        {
          'type': 'match_scheduled',
          'message': 'Próximo partido: vs Águilas - Dom 15:00',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 12))
              .toIso8601String(),
          'icon': 'event',
          'color': 'orange',
        },
      ],
    };
  }

  // Métricas para CAPITÁN DE EQUIPO - Gestión de SU equipo
  Map<String, dynamic> _getTeamCaptainMetrics() {
    return {
      'team_management': {
        'team_name': 'Leones FC',
        'total_players': 24,
        'active_players': 22,
        'inactive_players': 2,
        'new_this_month': 3,
        'pending_payments': 5,
      },
      'team_performance': {
        'matches_played': 8,
        'matches_won': 5,
        'matches_lost': 2,
        'matches_drawn': 1,
        'goals_scored': 22,
        'goals_conceded': 14,
        'current_position': 3,
      },
      'upcoming_events': {
        'next_match': 'vs Águilas FC - Dom 15:00',
        'next_training': 'Jue 19:00 - Estadio Municipal',
        'pending_meetings': 2,
      },
      'top_players': [
        {
          'name': 'Carlos Striker',
          'goals': 8,
          'position': 'Delantero',
        },
        {
          'name': 'Ana Midfielder',
          'goals': 5,
          'position': 'Mediocampo',
        },
        {
          'name': 'Luis Defender',
          'goals': 2,
          'position': 'Defensa',
        },
      ],
      'recentActivity': [
        {
          'type': 'player_joined',
          'message': 'Nuevo jugador: María González',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'icon': 'person_add',
          'color': 'blue',
        },
        {
          'type': 'match_result',
          'message': 'Victoria 2-1 vs Tigres FC',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'icon': 'sports_soccer',
          'color': 'green',
        },
        {
          'type': 'payment_reminder',
          'message': '5 jugadores con pagos pendientes',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 6))
              .toIso8601String(),
          'icon': 'payment',
          'color': 'orange',
        },
      ],
    };
  }

  // Métricas para MANAGER - Gestión de múltiples equipos
  Map<String, dynamic> _getManagerMetrics() {
    return {
      'organization_overview': {
        'total_teams': 4,
        'total_players': 68,
        'active_players': 62,
        'inactive_players': 6,
        'total_managers': 3,
        'new_registrations': 8,
      },
      'competition_stats': {
        'current_season': 'Liga Amateur 2024',
        'matchday': 8,
        'total_matchdays': 12,
        'matches_this_week': 6,
        'goals_total': 87,
        'average_goals_per_match': 4.8,
      },
      'financial_overview': {
        'total_collected': 15400,
        'pending_payments': 2800,
        'monthly_expenses': 8500,
        'balance': 4100,
      },
      'league_table': [
        {
          'position': 1,
          'team': 'Leones FC',
          'points': 21,
          'matches': 8,
          'wins': 7,
          'draws': 0,
          'losses': 1,
        },
        {
          'position': 2,
          'team': 'Águilas United',
          'points': 18,
          'matches': 8,
          'wins': 6,
          'draws': 0,
          'losses': 2,
        },
        {
          'position': 3,
          'team': 'Tigres Rojos',
          'points': 15,
          'matches': 8,
          'wins': 5,
          'draws': 0,
          'losses': 3,
        },
        {
          'position': 4,
          'team': 'Halcones FC',
          'points': 6,
          'matches': 8,
          'wins': 2,
          'draws': 0,
          'losses': 6,
        },
      ],
      'recentActivity': [
        {
          'type': 'match_result',
          'message': 'Resultado: Leones FC 3-1 Águilas United',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 4))
              .toIso8601String(),
          'icon': 'sports_soccer',
          'color': 'green',
        },
        {
          'type': 'team_created',
          'message': 'Nuevo equipo: Cóndores FC se unió a la liga',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'icon': 'group_add',
          'color': 'blue',
        },
        {
          'type': 'payment_received',
          'message': 'Pago recibido: Leones FC - ${2500}',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'icon': 'payment',
          'color': 'green',
        },
      ],
    };
  }
}

import 'dart:math';

class GameStatsService {
  GameStatsService();
  // Datos mock
  static final List<Map<String, dynamic>> teamStats = [
    {'title': 'Partidos Jugados', 'value': '24'},
    {'title': 'Goles Marcados', 'value': '56'},
    {'title': 'Goles Recibidos', 'value': '30'},
    {'title': 'Tarjetas Amarillas', 'value': '18'},
    {'title': 'Tarjetas Rojas', 'value': '8'},
  ];

  static final List<Map<String, dynamic>> goalsEvolution = [
    {'x': 1, 'scored': 5, 'conceded': 3},
    {'x': 2, 'scored': 8, 'conceded': 5},
    {'x': 3, 'scored': 6, 'conceded': 4},
  ];

  // Métodos para obtener los datos
  List<Map<String, dynamic>> getTeamStats() {
    return teamStats;
  }

  // Mock de estadísticas por jugador
  List<Map<String, dynamic>> getPlayerStats() {
    return [
      {
        'id': 1,
        'number': 10,
        'age': 47,
        'name': 'Cesar Gradito',
        'position': 'Delantero',
        'partidos jugados': 35,
        'goals': 12,
        'assists': 8,
        'minutesPlayed': 2900,
        'Remates al Arco': 15.0,
        'Pases Completados': 60.0,
        'Pases Errados': 10.0,
        'Tarjetas Amarillas': 8.0,
        'Tarjetas Rojas': 3.0,
      },
      {
        'id': 2,
        'number': 7,
        'age': 37,
        'name': 'Diego Nadaya',
        'position': 'Delantero',
        'partidos jugados': 25,
        'goals': 15,
        'assists': 5,
        'minutesPlayed': 1300,
        'Remates al Arco': 15.0,
        'Pases Completados': 60.0,
        'Pases Errados': 10.0,
        'Tarjetas Amarillas': 1.0,
        'Tarjetas Rojas': 0.0,
      },
      {
        'id': 3,
        'number': 3,
        'age': 42,
        'name': 'Maximiliano Rodriguez',
        'position': 'Defensor',
        'partidos jugados': 30,
        'goals': 2,
        'assists': 0,
        'minutesPlayed': 1800,
        'Remates al Arco': 15.0,
        'Pases Completados': 60.0,
        'Pases Errados': 10.0,
        'Tarjetas Amarillas': 1.0,
        'Tarjetas Rojas': 5.0,
      },
    ];
  }

  List<Map<String, dynamic>> getGoalsEvolution() {
    return goalsEvolution;
  }

  Map<String, dynamic> getPlayerDetails(int playerId) {
    final players = getPlayerStats();
    return players.firstWhere((player) => player['id'] == playerId,
        orElse: () => {});
  }
}

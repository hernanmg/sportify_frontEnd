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
        'partidosJugados': 35,
        'goals': 12,
        'assists': 18,
        'minutesPlayed': 2900,
        'rematesAlArco': 15.0,
        'pasesCompletados': 60.0,
        'pasesErrados': 10.0,
        'tarjetasAmarillas': 8.0,
        'tarjetasRojas': 3.0,
      },
      {
        'id': 2,
        'number': 7,
        'age': 37,
        'name': 'Diego Nadaya',
        'position': 'Delantero',
        'partidosJugados': 25,
        'goals': 15,
        'assists': 9,
        'minutesPlayed': 1300,
        'rematesAlArco': 15.0,
        'pasesCompletados': 60.0,
        'pasesErrados': 10.0,
        'tarjetasAmarillas': 1.0,
        'tarjetasRojas': 0.0,
      },
      {
        'id': 3,
        'number': 3,
        'age': 42,
        'name': 'Maximiliano Rodriguez',
        'position': 'Defensor',
        'partidosJugados': 30,
        'goals': 2,
        'assists': 1,
        'minutesPlayed': 1800,
        'rematesAlArco': 15.0,
        'pasesCompletados': 60.0,
        'pasesErrados': 10.0,
        'tarjetasAmarillas': 1.0,
        'tarjetasRojas': 5.0,
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

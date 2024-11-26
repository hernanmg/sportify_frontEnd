class GameStatsService {
  GameStatsService();
  // Datos mock
  static final List<Map<String, dynamic>> teamStats = [
    {'title': 'Partidos Jugados', 'value': '24'},
    {'title': 'Goles Marcados', 'value': '56'},
    {'title': 'Goles Recibidos', 'value': '30'},
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

  List<Map<String, dynamic>> getGoalsEvolution() {
    return goalsEvolution;
  }
}

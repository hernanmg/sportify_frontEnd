import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sportify_amateur/core/services/gamestat_service.dart';

class GameStatsScreen extends StatefulWidget {
  final bool? isAdmin;

  const GameStatsScreen({super.key, this.isAdmin});

  @override
  State<GameStatsScreen> createState() => _GameStatsScreenState();
}

class _GameStatsScreenState extends State<GameStatsScreen> {
  final GameStatsService mockService = GameStatsService();
  late bool isAdmin;
  late List<Map<String, dynamic>> teamStats;
  late List<Map<String, dynamic>> goalsEvolution;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadInitialData();
  }

  void _loadSession() {
    // Simula obtener datos de la sesión o token almacenado
    isAdmin = widget.isAdmin ?? getIsAdminFromSession();
  }

  bool getIsAdminFromSession() {
    // Implementa aquí la lógica para verificar si el usuario es admin
    return true; // Simulación
  }

  void _loadInitialData() {
    teamStats = mockService.getTeamStats();
    goalsEvolution = mockService.getGoalsEvolution();
  }

  void _refreshData() {
    setState(() {
      teamStats = mockService.getTeamStats();
      goalsEvolution = mockService.getGoalsEvolution();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Juego'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'register_events') {
                Navigator.pushNamed(context, '/events');
              }
              if (value == 'games') {
                Navigator.pushNamed(context, '/games');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'register_events',
                child: Text('Eventos'),
              ),
              const PopupMenuItem(
                value: 'games',
                child: Text('Partidos'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: teamStats
                    .map((stat) => _buildStatCard(stat['title'], stat['value']))
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Evolución de Goles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildGoalsChart(goalsEvolution)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/playerStats');
                  },
                  child: const Text('Ver Estadísticas por Jugador'),
                ),
                if (isAdmin)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/comparePlayers');
                    },
                    child: const Text('Comparar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsChart(List<Map<String, dynamic>> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: data
            .map((entry) => BarChartGroupData(x: entry['x'], barRods: [
                  BarChartRodData(
                      toY: entry['scored'].toDouble(), color: Colors.green),
                  BarChartRodData(
                      toY: entry['conceded'].toDouble(), color: Colors.red),
                ]))
            .toList(),
        titlesData: FlTitlesData(show: true),
      ),
    );
  }
}

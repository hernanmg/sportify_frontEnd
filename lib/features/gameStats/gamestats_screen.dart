import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sportify_amateur/core/services/gamestat_service.dart';

class GameStatsScreen extends StatefulWidget {
  const GameStatsScreen({super.key});

  @override
  State<GameStatsScreen> createState() => _GameStatsScreenState();
}

class _GameStatsScreenState extends State<GameStatsScreen> {
  final GameStatsService mockService = GameStatsService();

  late List<Map<String, dynamic>> teamStats;
  late List<Map<String, dynamic>> goalsEvolution;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Carga los datos iniciales desde el servicio mock
    teamStats = mockService.getTeamStats();
    goalsEvolution = mockService.getGoalsEvolution();
  }

  void _refreshData() {
    // Simula un refresco de datos
    setState(() {
      teamStats = mockService.getTeamStats(); // Podrías simular cambios aquí
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
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/playerStats');
              },
              child: const Text('Ver Estadísticas por Jugador'),
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

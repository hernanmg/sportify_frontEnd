import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sportify_amateur/core/services/gamestat_service.dart';

class ComparePlayersScreen extends StatefulWidget {
  const ComparePlayersScreen({super.key});

  @override
  State<ComparePlayersScreen> createState() => _ComparePlayersScreenState();
}

class _ComparePlayersScreenState extends State<ComparePlayersScreen> {
  final GameStatsService _gameStatsService = GameStatsService();

  List<Map<String, dynamic>> _allPlayers = [];
  final List<Map<String, dynamic>> _selectedPlayers = [];
  final List<String> _categories = [
    'Partidos',
    'Goles',
    'Asistencias',
    'Minutos',
    'Remates',
    'Pases Completados',
    'Pases Errados',
    'Tarj. Amarillas',
    'Tarj. Rojas',
  ];

  @override
  void initState() {
    super.initState();
    _allPlayers = _gameStatsService.getPlayerStats();
  }

  // Servicio que obtiene el número de partidos jugados del equipo
  int getTeamGamesPlayed() {
    // Suponiendo que obtienes este dato de un servicio
    return 38; // Ejemplo de cantidad de partidos jugados por el equipo
  }

  void _selectPlayer(Map<String, dynamic> player) {
    setState(() {
      if (!_selectedPlayers.contains(player) && _selectedPlayers.length < 3) {
        _selectedPlayers.add(player);
      }
    });
  }

  void _removePlayer(Map<String, dynamic> player) {
    setState(() {
      _selectedPlayers.remove(player);
    });
  }

  Widget _buildDropdown() {
    return DropdownButton<Map<String, dynamic>>(
      hint: const Text('Selecciona un jugador'),
      items: _allPlayers.map((player) {
        return DropdownMenuItem(
          value: player,
          child: Text(player['name']),
        );
      }).toList(),
      onChanged: (selected) {
        if (selected != null) {
          _selectPlayer(selected);
        }
      },
    );
  }

  Widget _buildSelectedPlayers() {
    return Wrap(
      spacing: 8.0,
      children: _selectedPlayers.map((player) {
        return Chip(
          label: Text(player['name']),
          onDeleted: () => _removePlayer(player),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonChart() {
    if (_selectedPlayers.isEmpty) {
      return const Center(
        child: Text('Selecciona al menos 1 jugador para comparar.'),
      );
    }

    final teamGamesPlayed =
        getTeamGamesPlayed(); // Obtener los partidos jugados del equipo
    final barGroups = _categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: _selectedPlayers.map((player) {
          double value;
          switch (category) {
            case 'Partidos':
              value = player['partidosJugados'].toDouble();
              break;
            case 'Goles':
              value = player['goals'].toDouble();
              break;
            case 'Asistencias':
              value = player['assists'].toDouble();
              break;
            case 'Minutos':
              value = player['minutesPlayed'] / 100; // Escalar los minutos
              break;
            case 'Remates':
              value = player['rematesAlArco'].toDouble();
              break;
            case 'Pases Completados':
              value = player['pasesCompletados'].toDouble() / 10;
              break;
            case 'Pases Errados':
              value = player['pasesErrados'].toDouble();
              break;
            case 'Tarj. Amarillas':
              value = player['tarjetasAmarillas'].toDouble();
              break;
            case 'Tarj. Rojas':
              value = player['tarjetasRojas'].toDouble();
              break;
            default:
              value = 0.0;
          }
          return BarChartRodData(
            toY: value,
            width: 15,
            color: Colors.primaries[
                _selectedPlayers.indexOf(player) % Colors.primaries.length],
          );
        }).toList(),
      );
    }).toList();

    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RotatedBox(
        quarterTurns: 3,
        child: Text(
          'Partidos Del Equipo',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
          child: SizedBox(
              height: 350,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1, // Mostrar pasos de 1 en el eje Y
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0 && value >= 0 && value <= 38) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize:
                            60, // Espacio reservado para evitar cortes
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= _categories.length) {
                            return const SizedBox.shrink();
                          }
                          return Transform.translate(
                              offset: const Offset(
                                  0, 10), // Ajustar para mayor claridad
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  _categories[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ));
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false, // Ocultar líneas verticales
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  maxY: teamGamesPlayed.toDouble(),
                ),
              )))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparar Jugadores'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown(),
            const SizedBox(height: 8),
            _buildSelectedPlayers(),
            const SizedBox(height: 16),
            Expanded(child: _buildComparisonChart()),
          ],
        ),
      ),
    );
  }
}

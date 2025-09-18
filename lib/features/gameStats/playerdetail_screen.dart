import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/gamestat_service.dart';

class PlayerDetailScreen extends StatefulWidget {
  final int playerId;
  PlayerDetailScreen({super.key, required this.playerId});

  @override
  _PlayerDetailScreenState createState() => _PlayerDetailScreenState();
}

double getValidValue(dynamic value) {
  if (value == null || value <= 0) {
    return 0.1; // Valor mínimo para evitar problemas
  }
  return value.toDouble();
}

double normalizeValue(dynamic value, double maxValue) {
  // Convierte el valor a double si es necesario
  double numericValue = value is int ? value.toDouble() : value;
  // Normaliza el valor entre 0 y 1, luego multiplica por 10 para la escala del gráfico
  return (numericValue / maxValue) * 10;
}

double angleValue = 0;
bool relativeAngleMode = true;

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final GameStatsService gameStatsService = GameStatsService();

  bool showRadarChart = false;

  @override
  Widget build(BuildContext context) {
    final player = gameStatsService.getPlayerDetails(widget.playerId);
    // Verificación de valores válidos
    final goals =
        (player['goals'] != null && player['goals'] >= 0) ? player['goals'] : 0;
    final assists = (player['assists'] != null && player['assists'] >= 0)
        ? player['assists']
        : 0;
    final minutesPlayed =
        (player['minutesPlayed'] != null && player['minutesPlayed'] >= 0)
            ? player['minutesPlayed']
            : 0;
// Método para generar los títulos dinámicos
//     List<String> getRadarTitles(Map<String, dynamic> player) {
//       return [
//         'Goles',
//         'Asistencias',
//         'Minutos Jugados',
//         'Remates al Arco',
//         'Pases Completados',
//         'Pases Errados',
//       ];
//     }

// // Método para generar el RadarDataSet
//     RadarDataSet generateRadarDataSet(Map<String, dynamic> player) {
//       return RadarDataSet(
//         dataEntries: [
//           RadarEntry(value: player['goals'].toDouble() / 10), // Escalado
//           RadarEntry(value: player['assists'].toDouble() / 10), // Escalado
//           RadarEntry(
//               value: player['minutesPlayed'].toDouble() / 1000), // Escalado
//           RadarEntry(value: player['Remates al Arco'] ), // Escalado
//           RadarEntry(value: player['Pases Completados']), // Escalado
//           RadarEntry(value: player['Pases Errados'] ), // Escalado
//         ],
//         fillColor: Colors.blue.withOpacity(0.4),
//         borderColor: Colors.blue,
//         entryRadius: 3,
//         borderWidth: 2,
//       );
//     }

//     final titles = getRadarTitles(player);
    // final partidosJugados = player['partidos jugados'].toDouble();

    // // Cálculo de promedios por partido
    // final data = [
    //   {'stat': 'Goles', 'value': player['goals'] / partidosJugados},
    //   {'stat': 'Asistencias', 'value': player['assists'] / partidosJugados},
    //   {
    //     'stat': 'Min. Jugados',
    //     'value': player['minutesPlayed'] / partidosJugados
    //   },
    //   {'stat': 'Remates', 'value': player['Remates al Arco'] / partidosJugados},
    //   {
    //     'stat': 'Pases Compl.',
    //     'value': player['Pases Completados'] / partidosJugados
    //   },
    //   {
    //     'stat': 'Pases Err.',
    //     'value': player['Pases Errados'] / partidosJugados
    //   },
    //   {
    //     'stat': 'T. Amarillas',
    //     'value': player['Tarjetas Amarillas'] / partidosJugados
    //   },
    //   {'stat': 'T. Rojas', 'value': player['Tarjetas Rojas'] / partidosJugados},
    // ];

    return Scaffold(
      appBar: AppBar(
        title: Text(player['name'] ?? 'Jugador no encontrado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información básica del jugador
            Text('Posición: ${player['position']}'),
            Text('Edad: ${player['age'] ?? 'Desconocida'} años'),
            const SizedBox(height: 30),

            // Selector para elegir el tipo de gráfico
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showRadarChart = false; // Gráfico de barras
                    });
                  },
                  child: const Text('Gráfico de Barras'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showRadarChart = true; // Gráfico de radar
                    });
                  },
                  child: const Text('Gráfico de Radar'),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Mostrar el gráfico correspondiente
            showRadarChart
                ? SizedBox(
                    height: 300,
                    child: RadarChart(
                      RadarChartData(
                        radarTouchData: RadarTouchData(
                          enabled: true,
                          touchCallback: (FlTouchEvent event,
                              RadarTouchResponse? response) {
                            if (event.isInterestedForInteractions &&
                                response != null) {
                              print('Touched: ${response.touchedSpot}');
                            }
                          },
                        ),
                        dataSets:
                            // [generateRadarDataSet(player)],
                            [
                          RadarDataSet(
                            dataEntries: [
                              RadarEntry(
                                  value: normalizeValue(goals,
                                      20)), // Normalizado para máximo de 20 goles
                              RadarEntry(
                                  value: normalizeValue(assists,
                                      15)), // Normalizado para máximo de 15 asistencias
                              RadarEntry(
                                  value: normalizeValue(minutesPlayed, 5400)),
                              RadarEntry(
                                  value: normalizeValue(
                                      player['rematesAlArco'], 20)),
                              RadarEntry(
                                  value: normalizeValue(
                                      player['pasesCompletados'], 100)),
                              RadarEntry(
                                  value: normalizeValue(
                                      player['pasesErrados'], 100)),
                              RadarEntry(
                                  value: normalizeValue(
                                      player['tarjetasAmarillas'], 100)),
                              RadarEntry(
                                  value: normalizeValue(
                                      player['tarjetasRojas'],
                                      100)), // Normalizado para máximo de 60 partidos (5400 minutos)
                            ],
                            fillColor: Colors.blue.withOpacity(0.2),
                            borderColor: Colors.blue,
                            entryRadius: 3,
                            borderWidth: 2,
                          ),
                        ],
                        radarBackgroundColor: Colors.transparent,
                        borderData: FlBorderData(show: false),
                        radarBorderData:
                            const BorderSide(color: Colors.blue, width: 2),
                        titlePositionPercentageOffset: 0.2,
                        tickCount: 5,
                        tickBorderData:
                            BorderSide(color: Colors.grey.shade300, width: 1),
                        titleTextStyle: const TextStyle(fontSize: 12),
                        getTitle:
                            // (index, _) =>
                            //     RadarChartTitle(text: titles[index]),
                            (index, angle) {
                          switch (index) {
                            case 0:
                              return RadarChartTitle(
                                text: 'Goles ($goals)',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 1:
                              return RadarChartTitle(
                                text: 'Asistencias ($assists)',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 2:
                              return RadarChartTitle(
                                text:
                                    'Minutos (${minutesPlayed ~/ 90} partidos)',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 3:
                              return RadarChartTitle(
                                text: 'Remates (${player['Remates al Arco']})',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 4:
                              return RadarChartTitle(
                                text: 'Pases (${player['Pases Completados']})',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 5:
                              return RadarChartTitle(
                                text:
                                    'Pases errados(${player['Pases Errados']} )',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 6:
                              return RadarChartTitle(
                                text:
                                    'Amarillas (${player['Tarjetas Amarillas']})',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            case 7:
                              return RadarChartTitle(
                                text: 'Rojas (${player['Tarjetas Rojas']})',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                            default:
                              return RadarChartTitle(
                                text: '',
                                angle: angle,
                                positionPercentageOffset: 0.15,
                              );
                          }
                        },
                        ticksTextStyle: const TextStyle(
                          color: Color.fromARGB(225, 12, 5, 1),
                          fontSize: 10,
                        ),
                        gridBorderData: BorderSide(
                            color: Colors.blue.withOpacity(0.4), width: 1),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Partidos',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                            height: 350,
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(show: true),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 60,
                                      getTitlesWidget: (value, meta) {
                                        switch (value.toInt()) {
                                          case 0:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('Min/Partido'));
                                          case 1:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('Goles'));
                                          case 2:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('Asistencias'));
                                          case 3:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('Remates'));
                                          case 4:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('Pases Compl.'));
                                          case 5:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('Pases Err.'));
                                          case 6:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('T. Amarillas'));
                                          case 7:
                                            return const RotatedBox(
                                                quarterTurns: 3,
                                                child: Text('T. Rojas'));
                                          default:
                                            return const Text('');
                                        }
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 5,
                                      getTitlesWidget: (value, meta) =>
                                          Text(value.toInt().toString()),
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: (player['minutesPlayed'] /
                                                  player['partidosJugados']) /
                                              10,
                                          color: Colors.blue,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['goals'].toDouble(),
                                          color: Colors.green,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['assists'].toDouble(),
                                          color: Colors.orange,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 3,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['rematesAlArco'],
                                          color: Colors.black,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 4,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['pasesCompletados'] / 10,
                                          color: Colors.purple,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 5,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['pasesErrados'],
                                          color: Colors.brown,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 6,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['tarjetasAmarillas'],
                                          color: Colors.yellow,
                                          width: 10),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 7,
                                    barRods: [
                                      BarChartRodData(
                                          fromY: 0,
                                          toY: player['tarjetasRojas'],
                                          color: Colors.red,
                                          width: 10),
                                    ],
                                  ),
                                ],
                                maxY: player['partidosJugados'] * 1.0,
                                barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                        final value = rod.toY *
                                            10; // Mostramos el valor real
                                        final label = [
                                          'Min/Partido',
                                          'Goles',
                                          'Asistencias',
                                          'Remates',
                                          'Pases Compl.',
                                          'Pases Err.',
                                          'T. Amarillas',
                                          'T. Rojas'
                                        ][group.x];
                                        return BarTooltipItem(
                                          '$label: ${value.toStringAsFixed(2)}',
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                    )),
                              ),
                            )),
                      ),
                    ],
                  ),
            const SizedBox(height: 30),
            // Agregar referencia sobre los valores divididos por 10
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nota: Minutos por partido y Pases Completados están divididos por 10 para mejor visualización.',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // Detalles adicionales del jugador
            // Text('Partidos Jugados: ${minutesPlayed ~/ 90}'),
            // Text('Remates al Arco: ${player['Remates al Arco']}'),
            // Text('Pases Completados: ${player['Pases Completados']}'),
            // Text('Pases Errados: ${player['Pases Errados']}'),
            // Text('Tarjetas Amarillas: ${player['Tarjetas Amarillas']}'),
            // Text('Tarjetas Rojas: ${player['Tarjetas Rojas']}'),
            const SizedBox(height: 20),

            // Botón de exportar
            ElevatedButton(
              onPressed: () {
                print('Exportar estadísticas del jugador');
              },
              child: const Text('Exportar Datos'),
            ),
          ],
        ),
      ),
    );
  }
}

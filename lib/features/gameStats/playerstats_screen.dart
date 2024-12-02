import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/gamestat_service.dart';
import 'package:sportify_amateur/features/gameStats/playerdetail_screen.dart';

class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({Key? key}) : super(key: key);

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final GameStatsService _gameStatsService = GameStatsService();
  List<Map<String, dynamic>> players = [];
  Map<String, dynamic>? selectedPlayer;

  @override
  void initState() {
    super.initState();
    players = _gameStatsService.getPlayerStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas por Jugador'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Seleccionar Jugador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<Map<String, dynamic>>(
              hint: const Text('Seleccione un jugador'),
              value: selectedPlayer,
              items: players
                  .map((player) => DropdownMenuItem<Map<String, dynamic>>(
                        value: player,
                        child: Text(player['name']),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedPlayer = value;
                });
              },
            ),
          ),
          if (selectedPlayer != null)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerDetailScreen(playerId: selectedPlayer!['id']),
                  ),
                );
              },
              child: const Text('Ver Detalle'),
            ),
        ],
      ),
    );
  }
}

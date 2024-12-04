import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/events/events_screen.dart';
import 'package:sportify_amateur/models/game.dart';

class GameDetailScreen extends StatelessWidget {
  final Game partido;

  GameDetailScreen({required this.partido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${partido.equipoLocal} vs ${partido.equipoVisitante}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha: ${partido.fecha}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Hora: ${partido.hora}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventsScreen(partidoId: partido.id),
                  ),
                );
                print('Gestionar eventos del partido ${partido.id}');
              },
              child: Text('Gestionar Eventos'),
            ),
          ],
        ),
      ),
    );
  }
}

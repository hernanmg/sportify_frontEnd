import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/game_service.dart';
import 'package:sportify_amateur/features/games/games_form_screen.dart';
import 'package:sportify_amateur/features/games/games_detail_screen.dart';
import 'package:sportify_amateur/models/game.dart';

class GamesScreen extends StatefulWidget {
  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final GamesService _gameService = GamesService();
  late Future<List<Game>> _partidos;

  @override
  void initState() {
    super.initState();
    _partidos = _gameService.obtenerPartidos();
  }

void _agregarPartido() async {
  final nuevoPartido = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GamesFormScreen(servicio: _gameService),
    ),
  );

  if (nuevoPartido != null) {
    setState(() {
      _partidos = _gameService.obtenerPartidos();
    });
  }
}

void _gestionarPartido(Game partido) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GameDetailScreen(partido: partido),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Partidos'),
      ),
      body: FutureBuilder<List<Game>>(
        future: _partidos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los partidos'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay partidos programados.'));
          }

          final partidos = snapshot.data!;
          return ListView.builder(
            itemCount: partidos.length,
            itemBuilder: (context, index) {
              final partido = partidos[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${partido.equipoLocal} vs ${partido.equipoVisitante}'),
                  subtitle: Text('${partido.fecha} - ${partido.hora}'),
                  trailing: ElevatedButton(
                    onPressed: () => _gestionarPartido(partido),
                    child: Text('Gestionar'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarPartido,
        child: Icon(Icons.add),
      ),
    );
  }
}

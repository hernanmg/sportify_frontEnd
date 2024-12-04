import 'dart:async';

import 'package:sportify_amateur/models/game.dart';

class GamesService {
  final List<Game> _partidos = [
    Game(
      id: '1',
      equipoLocal: 'Zebra+35',
      equipoVisitante: 'Equipo B',
      fecha: '2024-12-05',
      hora: '16:00',
    ),
    Game(
      id: '2',
      equipoLocal: 'Zebra+35',
      equipoVisitante: 'Equipo D',
      fecha: '2024-12-07',
      hora: '18:00',
    ),
  ];

  Future<List<Game>> obtenerPartidos() async {
    return Future.delayed(Duration(milliseconds: 500), () => _partidos);
  }

  Future<void> agregarPartido(Game partido) async {
    return Future.delayed(Duration(milliseconds: 300), () {
      _partidos.add(partido);
    });
  }
}

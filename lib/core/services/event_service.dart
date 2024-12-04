import 'dart:async';

import 'package:sportify_amateur/models/event.dart';

class EventService {
  final Map<String, List<Event>> _eventosPorPartido = {};
  final List<Event> _events_partidos = [
    Event(id: '1', gameId: '1', tipoEvento: '1', jugador: '1', minuto: 34),
    Event(id: '2', gameId: '1', tipoEvento: '1', jugador: '2', minuto: 54),
  ];
  Future<List<Event>> obtenerEventos(String partidoId) async {
    return Future.delayed(
      Duration(milliseconds: 500),
      () => _eventosPorPartido[partidoId] ?? _events_partidos,
    );
  }

  Future<void> agregarEvento(String partidoId, Event evento) async {
    if (!_eventosPorPartido.containsKey(partidoId)) {
      _eventosPorPartido[partidoId] = [];
    }
    _eventosPorPartido[partidoId]!.add(evento);

      // Emitir notificación para los usuarios suscritos
  }
}

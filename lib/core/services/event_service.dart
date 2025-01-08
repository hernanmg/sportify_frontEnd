import 'dart:async';

import 'package:sportify_amateur/models/event.dart';

class EventService {
  final Map<String, List<Event>> _eventosPorPartido = {};
  final List<Event> _events_partidos = [
    Event(
        id: '1',
        gameId: '1',
        type: EventType.game,
        jugador: '1',
        minuto: 34,
        location: '',
        startTime: DateTime.now(),
        durationMinutes: 60,
        fieldNumber: '',
        attendance: {
          'John Doe': AttendanceStatus.attending,
          'Jane Smith': AttendanceStatus.maybe,
          'Mike Johnson': AttendanceStatus.notAttending,
        },
        teamId: ''),
    Event(
        id: '2',
        gameId: '1',
        type: EventType.game,
        jugador: '2',
        minuto: 54,
        location: '',
        startTime: DateTime.now(),
        durationMinutes: 60,
        fieldNumber: '',
        attendance: {
          'John Doe': AttendanceStatus.attending,
          'Jane Smith': AttendanceStatus.maybe,
          'Mike Johnson': AttendanceStatus.notAttending,
        },
        teamId: ''),
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

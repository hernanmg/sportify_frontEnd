import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/event_service.dart';
import 'package:sportify_amateur/features/events/events_form_screen.dart';
import 'package:sportify_amateur/models/event.dart';

class EventsScreen extends StatefulWidget {
  final String partidoId;

  EventsScreen({required this.partidoId});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _eventos = [];
  final EventService servicio = EventService();
  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  void _cargarEventos() async {
    final eventos = await servicio.obtenerEventos(widget.partidoId);
    setState(() {
      _eventos = eventos;
    });
  }

  void _agregarEvento() async {
    final nuevoEvento = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventsFormScreen(
          partidoId: widget.partidoId,
        ),
      ),
    );

    if (nuevoEvento != null) {
      _cargarEventos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventos del Partido'),
      ),
      body: ListView.builder(
        itemCount: _eventos.length,
        itemBuilder: (context, index) {
          final evento = _eventos[index];
          return ListTile(
            title: Text('${evento.tipoEvento} - ${evento.jugador}'),
            subtitle: Text('Minuto: ${evento.minuto}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarEvento,
        child: Icon(Icons.add),
      ),
    );
  }
}

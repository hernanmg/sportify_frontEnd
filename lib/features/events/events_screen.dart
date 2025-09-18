import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/event_service.dart';
import 'package:sportify_amateur/features/events/events_detail_screen.dart';
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
          final event = _eventos[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Color(0xFF2A2D3E),
            child: ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEventTypeIcon(event.type),
                  color: Colors.white,
                ),
              ),
              title: Text(
                event.type.toString().split('.').last,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${event.location} - ${_formatDateTime(event.startTime)}',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla de agregar evento
          print('nuevo partido');
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.training:
        return Colors.blue;
      case EventType.game:
        return Colors.red;
      case EventType.strength:
        return Colors.orange;
      case EventType.testing:
        return Colors.purple;
      case EventType.recover:
        return Colors.green;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.training:
        return Icons.sports;
      case EventType.game:
        return Icons.sports_soccer;
      case EventType.strength:
        return Icons.fitness_center;
      case EventType.testing:
        return Icons.speed;
      case EventType.recover:
        return Icons.healing;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/event_service.dart';
import 'package:sportify_amateur/models/event.dart';

class EventsFormScreen extends StatefulWidget {
  final String partidoId;

  EventsFormScreen({required this.partidoId});

  @override
  _EventsFormScreenScreenState createState() => _EventsFormScreenScreenState();
}

class _EventsFormScreenScreenState extends State<EventsFormScreen> {
  final EventService servicio = EventService();

  final _formKey = GlobalKey<FormState>();
  String? _tipo;
  String? _jugador;
  String? _minuto;

  void _guardarEvento() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final evento = Event(
        id: DateTime.now().toString(), // ID temporal.
        gameId: widget.partidoId,
        tipoEvento: _tipo!,
        jugador: _jugador!,
        minuto: int.parse(_minuto!),
      );

      servicio.agregarEvento(widget.partidoId, evento).then((_) {
        Navigator.pop(context, evento);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Evento'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Tipo de Evento'),
                items: [
                  DropdownMenuItem(value: 'Gol', child: Text('Gol')),
                  DropdownMenuItem(
                      value: 'Asistencia', child: Text('Asistencia')),
                  DropdownMenuItem(
                      value: 'Tarjeta Amarilla',
                      child: Text('Tarjeta Amarilla')),
                  DropdownMenuItem(
                      value: 'Tarjeta Roja', child: Text('Tarjeta Roja')),
                ],
                onChanged: (value) => setState(() => _tipo = value),
                validator: (value) =>
                    value == null ? 'Seleccione el tipo de evento' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Jugador'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el nombre del jugador'
                    : null,
                onSaved: (value) => _jugador = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Minuto'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el minuto del evento'
                    : null,
                onSaved: (value) => _minuto = value,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarEvento,
                child: Text('Guardar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

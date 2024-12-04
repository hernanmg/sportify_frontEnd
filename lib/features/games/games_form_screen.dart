import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/game_service.dart';
import 'package:sportify_amateur/models/game.dart';

class GamesFormScreen extends StatefulWidget {
  final GamesService servicio;

  GamesFormScreen({required this.servicio});

  @override
  _GamesFormScreenState createState() => _GamesFormScreenState();
}

class _GamesFormScreenState extends State<GamesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _equipoLocal;
  String? _equipoVisitante;
  DateTime? _fecha;
  TimeOfDay? _hora;

  void _guardarPartido() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_fecha != null && _hora != null) {
        final partido = Game(
          id: DateTime.now().toString(), // ID temporal.
          equipoLocal: _equipoLocal!,
          equipoVisitante: _equipoVisitante!,
          fecha: '${_fecha!.year}-${_fecha!.month}-${_fecha!.day}',
          hora: '${_hora!.hour}:${_hora!.minute}',
        );

        widget.servicio.agregarPartido(partido).then((_) {
          Navigator.pop(context, partido);
        });
      }
    }
  }

  void _seleccionarFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (fechaSeleccionada != null) {
      setState(() => _fecha = fechaSeleccionada);
    }
  }

  void _seleccionarHora() async {
    final horaSeleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (horaSeleccionada != null) {
      setState(() => _hora = horaSeleccionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Partido'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Equipo Local'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Por favor ingrese el equipo local'
                    : null,
                onSaved: (value) => _equipoLocal = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Equipo Visitante'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Por favor ingrese el equipo visitante'
                    : null,
                onSaved: (value) => _equipoVisitante = value,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  _fecha == null
                      ? 'Seleccionar Fecha'
                      : '${_fecha!.year}-${_fecha!.month}-${_fecha!.day}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              ListTile(
                title: Text(
                  _hora == null
                      ? 'Seleccionar Hora'
                      : '${_hora!.hour}:${_hora!.minute}',
                ),
                trailing: Icon(Icons.access_time),
                onTap: _seleccionarHora,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardarPartido,
                child: Text('Guardar Partido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

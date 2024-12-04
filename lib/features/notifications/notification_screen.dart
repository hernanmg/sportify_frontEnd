import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationsService notificacionesService;

  NotificationsScreen({required this.notificacionesService});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int? _partidoSeleccionado;
  late Stream<String> _notificacionesStream;
  final List<String> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _notificacionesStream =
        Stream.empty(); // Inicial vacío hasta seleccionar partido
  }

  void _seleccionarPartido(int? partidoId) {
    if (partidoId != null) {
      setState(() {
        _partidoSeleccionado = partidoId;
        _notificaciones.clear(); // Limpiar notificaciones anteriores
        _notificacionesStream = widget.notificacionesService
            .obtenerNotificacionesParaPartido(partidoId);
      });
      _suscribirseANotificaciones();
    }
  }

  void _suscribirseANotificaciones() {
    _notificacionesStream.listen((mensaje) {
      setState(() {
        _notificaciones.add(mensaje);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notificaciones en Tiempo Real')),
      body: Column(
        children: [
          // Simula una lista de partidos
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<int>(
              hint: Text('Selecciona un partido'),
              value: _partidoSeleccionado,
              onChanged: _seleccionarPartido,
              items: [
                DropdownMenuItem(value: 1, child: Text('Partido 1')),
                DropdownMenuItem(value: 2, child: Text('Partido 2')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notificaciones.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_notificaciones[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

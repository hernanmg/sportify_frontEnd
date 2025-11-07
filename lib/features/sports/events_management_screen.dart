import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/models/sport_event.dart';
import 'package:sportify_amateur/features/sports/event_form_screen.dart';
import 'package:sportify_amateur/features/sports/event_detail_screen.dart';
import 'package:sportify_amateur/core/services/debug_service.dart';

class EventsManagementScreen extends StatefulWidget {
  const EventsManagementScreen({Key? key}) : super(key: key);

  @override
  _EventsManagementScreenState createState() => _EventsManagementScreenState();
}

class _EventsManagementScreenState extends State<EventsManagementScreen> {
  final SportEventsService _eventsService = SportEventsService();
  List<SportEvent> _events = [];
  List<SportEvent> _filteredEvents = [];
  bool _isLoading = true;
  SportEventType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() => _isLoading = true);
      final events = await _eventsService.getAllEvents(
          teamId: 2); // Equipo con jugadores en roster
      setState(() {
        _events = events;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar eventos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredEvents = List.from(_events);
    } else {
      _filteredEvents =
          _events.where((event) => event.type == _selectedFilter).toList();
    }
    _filteredEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading ? _buildLoadingWidget() : _buildEventsList(),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando eventos...'),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<SportEventType?>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Filtrar por tipo',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<SportEventType?>(
                  value: null,
                  child: Text('Todos los eventos'),
                ),
                ...SportEventType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getEventTypeName(type)),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value;
                  _applyFilter();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _createEvent,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _debugConnection,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug conexión',
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay eventos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == null
                  ? 'No tienes eventos programados'
                  : 'No hay eventos de este tipo',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(SportEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildEventIcon(event.type),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(event.formattedDate),
              ],
            ),
            if (event.location != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(event.location!)),
                ],
              ),
            ],
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${event.participantCount} participantes'),
                const Spacer(),
                _buildStatusChip(event.status),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleEventAction(value, event),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'participants',
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Ver participantes'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (event.type == SportEventType.match)
              const PopupMenuItem(
                value: 'convocation',
                child: ListTile(
                  leading: Icon(Icons.sports_soccer),
                  title: Text('Gestionar convocatoria'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _viewEventDetails(event),
      ),
    );
  }

  Widget _buildEventIcon(SportEventType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SportEventType.training:
        iconData = Icons.fitness_center;
        iconColor = Colors.orange;
        break;
      case SportEventType.match:
        iconData = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case SportEventType.social:
        iconData = Icons.celebration;
        iconColor = Colors.pink;
        break;
      case SportEventType.meeting:
        iconData = Icons.meeting_room;
        iconColor = Colors.blue;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildStatusChip(SportEventStatus status) {
    Color color;
    String label;

    switch (status) {
      case SportEventStatus.draft:
        color = Colors.grey;
        label = 'Borrador';
        break;
      case SportEventStatus.scheduled:
        color = Colors.blue;
        label = 'Programado';
        break;
      case SportEventStatus.confirmed:
        color = Colors.green;
        label = 'Confirmado';
        break;
      case SportEventStatus.inProgress:
        color = Colors.amber;
        label = 'En progreso';
        break;
      case SportEventStatus.completed:
        color = Colors.teal;
        label = 'Completado';
        break;
      case SportEventStatus.cancelled:
        color = Colors.red;
        label = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _createEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormScreen(),
      ),
    );

    if (result == true) {
      _loadEvents(); // Recargar eventos si se creó uno nuevo
    }
  }

  void _handleEventAction(String action, SportEvent event) {
    switch (action) {
      case 'edit':
        _editEvent(event);
        break;
      case 'participants':
        _viewParticipants(event);
        break;
      case 'convocation':
        _manageConvocation(event);
        break;
      case 'delete':
        _deleteEvent(event);
        break;
    }
  }

  void _editEvent(SportEvent event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(event: event),
      ),
    );

    if (result == true) {
      _loadEvents(); // Recargar eventos si se editó
    }
  }

  void _viewParticipants(SportEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _manageConvocation(SportEvent event) {
    // Navegar a la pantalla de convocatorias con este evento específico
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gestionar convocatoria para: ${event.title}'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            // TODO: Navegar a convocatorias con filtro por este evento
          },
        ),
      ),
    );
  }

  void _deleteEvent(SportEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content:
            Text('¿Estás seguro de que quieres eliminar "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _eventsService.deleteEvent(event.id);
                _loadEvents(); // Recargar lista
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar evento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _viewEventDetails(SportEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  String _getEventTypeName(SportEventType type) {
    switch (type) {
      case SportEventType.training:
        return 'Entrenamientos';
      case SportEventType.match:
        return 'Partidos';
      case SportEventType.social:
        return 'Eventos Sociales';
      case SportEventType.meeting:
        return 'Reuniones';
    }
  }

  void _debugConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Verificando conexión...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Probando autenticación y backend'),
          ],
        ),
      ),
    );

    try {
      await DebugService.printDebugInfo();
      final authStatus = await DebugService.checkAuthStatus();
      final healthCheck = await DebugService.checkBackendHealth();

      Navigator.pop(context); // Cerrar dialog de carga

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Estado de Conexión'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Backend: ${healthCheck['backendOnline'] ? '✅ Conectado' : '❌ Desconectado'}'),
                const SizedBox(height: 8),
                Text(
                    'Autenticación: ${authStatus['isAuthenticated'] ? '✅ Válida' : '❌ Inválida'}'),
                const SizedBox(height: 8),
                if (authStatus['token'] != null)
                  Text('Token: ${authStatus['token']}'),
                const SizedBox(height: 8),
                if (authStatus['error'] != null)
                  Text('Error: ${authStatus['error']}',
                      style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                if (authStatus['userInfo'] != null) ...[
                  if (authStatus['userInfo']['user'] != null) ...[
                    Text(
                        'Usuario: ${authStatus['userInfo']['user']['username'] ?? 'N/A'}'),
                    Text(
                        'Email: ${authStatus['userInfo']['user']['email'] ?? 'N/A'}'),
                    Text(
                        'Rol: ${authStatus['userInfo']['user']['role'] ?? 'N/A'}'),
                  ] else
                    Text('Info: ${authStatus['userInfo'].toString()}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            if (!authStatus['isAuthenticated'])
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Ir a Login'),
              ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Cerrar dialog de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en debug: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

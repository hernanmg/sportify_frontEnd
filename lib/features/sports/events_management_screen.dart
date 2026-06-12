import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/sport_event.dart';
import 'package:sportify_amateur/features/sports/event_form_screen.dart';
import 'package:sportify_amateur/features/sports/event_detail_screen.dart';
import 'package:sportify_amateur/features/sports/team_calendar_screen.dart';

class EventsManagementScreen extends StatefulWidget {
  const EventsManagementScreen({Key? key}) : super(key: key);

  @override
  EventsManagementScreenState createState() => EventsManagementScreenState();
}

class EventsManagementScreenState extends State<EventsManagementScreen> {
  final SportEventsService _eventsService = SportEventsService();
  final TeamService _teamService = TeamService();
  List<SportEvent> _events = [];
  List<SportEvent> _filteredEvents = [];
  bool _isLoading = true;
  SportEventType? _selectedFilter;
  bool _canDeleteEvents = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadEvents();
  }

  Future<void> _loadRole() async {
    final role = await AuthStorageService().getRole();
    final canDelete = role == 'super_admin' ||
        role == 'manager' ||
        role == 'admin' ||
        role == 'dt' ||
        role == 'team_captain';
    if (mounted) setState(() => _canDeleteEvents = canDelete);
  }

  Future<void> reloadEvents() => _loadEvents();

  Future<void> _loadEvents() async {
    try {
      setState(() => _isLoading = true);
      final myTeams = await _teamService.getMyTeams();
      final teamIds = myTeams.map((t) => t.teamId).toSet().toList();
      List<SportEvent> events;
      if (teamIds.isEmpty) {
        events = [];
      } else if (teamIds.length == 1) {
        events = await _eventsService.getAllEvents(teamId: teamIds.first);
      } else {
        final seen = <int>{};
        events = [];
        for (final id in teamIds) {
          try {
            final list = await _eventsService.getAllEvents(teamId: id);
            for (final ev in list) {
              if (seen.add(ev.id)) events.add(ev);
            }
          } catch (_) {}
        }
        events.sort(_compareEvents);
      }
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
    _filteredEvents.sort(_compareEvents);
  }

  int _typeSortOrder(SportEventType type) {
    switch (type) {
      case SportEventType.training:
        return 0;
      case SportEventType.match:
        return 1;
      case SportEventType.meeting:
        return 2;
      case SportEventType.social:
        return 3;
    }
  }

  int _compareEvents(SportEvent a, SportEvent b) {
    final typeCmp =
        _typeSortOrder(a.type).compareTo(_typeSortOrder(b.type));
    if (typeCmp != 0) return typeCmp;
    return a.eventDate.compareTo(b.eventDate);
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
          IconButton(
            tooltip: 'Calendario',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const TeamCalendarScreen(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _createEvent,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
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
    final card = Card(
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
                Expanded(
                  child: Text(
                    event.formattedDate,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${event.participantCount} participantes'),
                  ],
                ),
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
            if (_canDeleteEvents)
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

    if (!_canDeleteEvents) return card;

    return Dismissible(
      key: ValueKey('event-${event.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar evento'),
                content: Text('¿Eliminar "${event.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _performDelete(event),
      child: card,
    );
  }

  Future<void> _performDelete(SportEvent event) async {
    try {
      await _eventsService.deleteEvent(event.id);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      case SportEventStatus.postponed:
        color = Colors.orange;
        label = 'Pospuesto';
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
              await _performDelete(event);
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

}

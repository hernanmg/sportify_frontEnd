import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/core/services/team_calendar_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/sports/convocation_form_screen.dart';
import 'package:sportify_amateur/features/sports/event_detail_screen.dart';
import 'package:sportify_amateur/features/sports/event_form_screen.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/team_calendar_item.dart';
import 'package:table_calendar/table_calendar.dart';

class TeamCalendarScreen extends StatefulWidget {
  final int? initialTeamId;

  const TeamCalendarScreen({super.key, this.initialTeamId});

  @override
  State<TeamCalendarScreen> createState() => _TeamCalendarScreenState();
}

class _TeamCalendarScreenState extends State<TeamCalendarScreen> {
  final _calendarService = TeamCalendarService();
  final _teamService = TeamService();
  final _eventsService = SportEventsService();

  List<MyTeamOption> _teams = [];
  int? _teamId;
  String _teamName = '';
  bool _loadingTeams = true;
  bool _loadingCalendar = false;
  String? _error;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _kindsFilter = 'all';

  final Map<DateTime, List<TeamCalendarItem>> _itemsByDay = {};
  List<TeamCalendarItem> _allItems = [];

  String? _userRole;
  DateTime? _lastTappedDay;
  DateTime? _lastTapAt;

  bool get _canCreateConvocation {
    final r = _userRole;
    return r == 'super_admin' ||
        r == 'manager' ||
        r == 'admin' ||
        r == 'team_captain' ||
        r == 'dt';
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
    _initTeams();
  }

  Future<void> _loadRole() async {
    final role = await AuthStorageService().getRole();
    if (mounted) setState(() => _userRole = role);
  }

  String _birthdayTitle(TeamCalendarItem item) {
    final name = item.userName?.trim();
    if (name != null && name.isNotEmpty) {
      return 'Cumple de $name';
    }
    final title = item.title.trim();
    if (title.contains('displayName')) {
      return 'Cumpleaños del plantel';
    }
    return title;
  }

  Future<void> _initTeams() async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _loadingTeams = false;
        if (teams.isEmpty) {
          _error = 'No tenés equipos asignados';
          return;
        }
        _teamId = widget.initialTeamId != null &&
                teams.any((t) => t.teamId == widget.initialTeamId)
            ? widget.initialTeamId
            : teams.first.teamId;
        _teamName = teams
            .firstWhere(
              (t) => t.teamId == _teamId,
              orElse: () => teams.first,
            )
            .name;
      });
      await _loadCalendar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTeams = false;
        _error = e.toString();
      });
    }
  }

  DateTime _monthStart(DateTime day) =>
      DateTime(day.year, day.month, 1);

  DateTime _monthEnd(DateTime day) =>
      DateTime(day.year, day.month + 1, 0, 23, 59, 59, 999);

  Future<void> _loadCalendar() async {
    final teamId = _teamId;
    if (teamId == null) return;
    setState(() {
      _loadingCalendar = true;
      _error = null;
    });
    try {
      final from = _monthStart(_focusedDay).subtract(const Duration(days: 7));
      final to = _monthEnd(_focusedDay).add(const Duration(days: 7));
      final response = await _calendarService.getTeamCalendar(
        teamId: teamId,
        from: from,
        to: to,
        kinds: _kindsFilter,
      );
      if (!mounted) return;
      final grouped = <DateTime, List<TeamCalendarItem>>{};
      for (final item in response.items) {
        final key = DateTime(item.date.year, item.date.month, item.date.day);
        grouped.putIfAbsent(key, () => []).add(item);
      }
      setState(() {
        _teamName = response.teamName;
        _allItems = response.items;
        _itemsByDay
          ..clear()
          ..addAll(grouped);
        _loadingCalendar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCalendar = false;
        _error = e.toString();
      });
    }
  }

  List<TeamCalendarItem> _itemsOnDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _itemsByDay[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final now = DateTime.now();
    final isDoubleTap = _lastTappedDay != null &&
        isSameDay(_lastTappedDay!, selectedDay) &&
        _lastTapAt != null &&
        now.difference(_lastTapAt!) < const Duration(milliseconds: 500);

    _lastTappedDay = selectedDay;
    _lastTapAt = now;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    if (isDoubleTap) {
      _showCreateActions(selectedDay);
      return;
    }

    final items = _itemsOnDay(selectedDay);
    if (items.isNotEmpty) {
      _showDaySheet(selectedDay, items);
    }
  }

  void _showCreateActions(DateTime day) {
    final label = DateFormat('d MMMM', 'es').format(day);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Acciones para el $label',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.event, color: Colors.blue.shade800),
                ),
                title: const Text('Crear evento'),
                subtitle: const Text('Entrenamiento, partido o social'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateEvent(day);
                },
              ),
              if (_canCreateConvocation)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.sports_soccer, color: Colors.green.shade800),
                  ),
                  title: const Text('Crear convocatoria'),
                  subtitle: const Text('Partido con lista de convocados'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openCreateConvocation(day);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateEvent(DateTime day) async {
    final teamId = _teamId;
    if (teamId == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => EventFormScreen(
          initialDate: DateTime(day.year, day.month, day.day),
          initialTime: const TimeOfDay(hour: 19, minute: 0),
          initialTeamId: teamId,
        ),
      ),
    );
    if (mounted) await _loadCalendar();
  }

  Future<void> _openCreateConvocation(DateTime day) async {
    final teamId = _teamId;
    if (teamId == null) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => ConvocationFormScreen(
          initialMatchDate: DateTime(day.year, day.month, day.day),
          initialMatchTime: const TimeOfDay(hour: 16, minute: 0),
          initialTeamId: teamId,
        ),
      ),
    );
    if (mounted) await _loadCalendar();
  }

  Future<void> _openEvent(int eventId) async {
    try {
      final event = await _eventsService.getEventById(eventId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => EventDetailScreen(event: event),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el evento: $e')),
      );
    }
  }

  void _showDaySheet(DateTime day, List<TeamCalendarItem> items) {
    final label = DateFormat('EEEE d MMMM', 'es').format(day);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label[0].toUpperCase() + label.substring(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) => _buildSheetTile(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTile(TeamCalendarItem item) {
    final isBirthday = item.kind == TeamCalendarItemKind.birthday;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isBirthday ? Colors.purple.shade100 : Colors.blue.shade100,
          child: Icon(
            isBirthday ? Icons.cake : Icons.event,
            color: isBirthday ? Colors.purple.shade800 : Colors.blue.shade800,
          ),
        ),
        title: Text(isBirthday ? _birthdayTitle(item) : item.title),
        subtitle: Text(
          isBirthday
              ? (item.dayMonthLabel ?? item.subtitle ?? '')
              : [
                  if (item.eventType != null) _eventTypeLabel(item.eventType!),
                  if (item.location != null && item.location!.isNotEmpty)
                    item.location!,
                  if (!isBirthday)
                    DateFormat('HH:mm').format(item.date),
                ].where((s) => s.isNotEmpty).join(' · '),
        ),
        onTap: isBirthday
            ? null
            : () {
                Navigator.pop(context);
                if (item.sportEventId != null) {
                  _openEvent(item.sportEventId!);
                }
              },
      ),
    );
  }

  String _eventTypeLabel(String type) {
    switch (type) {
      case 'training':
        return 'Entrenamiento';
      case 'match':
        return 'Partido';
      case 'social':
        return 'Social';
      case 'meeting':
        return 'Reunión';
      default:
        return type;
    }
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _legendDot(Colors.blue, 'Eventos'),
          const SizedBox(width: 16),
          _legendDot(Colors.purple, 'Cumpleaños'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          if (_loadingCalendar)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCalendar,
            ),
        ],
      ),
      body: _loadingTeams
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(child: Text(_error ?? 'Sin equipos'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_teams.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: DropdownButtonFormField<int>(
                          value: _teamId,
                          decoration: const InputDecoration(
                            labelText: 'Equipo',
                            border: OutlineInputBorder(),
                          ),
                          items: _teams
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t.teamId,
                                  child: Text(t.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _teamId = v;
                              _teamName = _teams
                                  .firstWhere((t) => t.teamId == v)
                                  .name;
                            });
                            _loadCalendar();
                          },
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          _teamName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('Todo')),
                          ButtonSegment(value: 'events', label: Text('Eventos')),
                          ButtonSegment(
                            value: 'birthdays',
                            label: Text('Cumpleaños'),
                          ),
                        ],
                        selected: {_kindsFilter},
                        onSelectionChanged: (set) {
                          setState(() => _kindsFilter = set.first);
                          _loadCalendar();
                        },
                      ),
                    ),
                    _buildLegend(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Doble toque en un día: crear evento'
                        '${_canCreateConvocation ? ' o convocatoria' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TableCalendar<TeamCalendarItem>(
                      locale: 'es',
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      eventLoader: _itemsOnDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      onDaySelected: _onDaySelected,
                      onFormatChanged: (format) {
                        setState(() => _calendarFormat = format);
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadCalendar();
                      },
                      calendarStyle: CalendarStyle(
                        markerDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return null;
                          final hasBirthday = events.any(
                            (e) => e.kind == TeamCalendarItemKind.birthday,
                          );
                          final hasEvent = events.any(
                            (e) => e.kind == TeamCalendarItemKind.event,
                          );
                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasEvent)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasBirthday)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildSelectedDayList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSelectedDayList() {
    final items = _itemsOnDay(_selectedDay);
    if (items.isEmpty) {
      final monthItems = _allItems
          .where((i) =>
              i.date.year == _focusedDay.year &&
              i.date.month == _focusedDay.month)
          .toList();
      if (monthItems.isEmpty) {
        return Center(
          child: Text(
            _error ?? 'Sin actividades este mes',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Este mes en $_teamName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...monthItems.map(_buildListTile),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          DateFormat('d MMMM', 'es').format(_selectedDay),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(_buildListTile),
      ],
    );
  }

  Widget _buildListTile(TeamCalendarItem item) {
    final isBirthday = item.kind == TeamCalendarItemKind.birthday;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isBirthday ? Colors.purple.shade50 : Colors.blue.shade50,
      child: ListTile(
        leading: Icon(
          isBirthday ? Icons.cake : Icons.event,
          color: isBirthday ? Colors.purple.shade700 : Colors.blue.shade700,
        ),
        title: Text(isBirthday ? _birthdayTitle(item) : item.title),
        subtitle: Text(
          isBirthday
              ? (item.dayMonthLabel ?? '')
              : DateFormat('HH:mm').format(item.date),
        ),
        onTap: isBirthday
            ? null
            : () {
                if (item.sportEventId != null) {
                  _openEvent(item.sportEventId!);
                }
              },
      ),
    );
  }
}

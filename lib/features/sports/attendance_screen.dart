import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/attendance_service.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/features/sports/event_attendance_screen.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class AttendanceScreen extends StatefulWidget {
  final int teamId;

  const AttendanceScreen({super.key, required this.teamId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _attendanceService = AttendanceService();
  final _eventsService = SportEventsService();

  TeamAttendanceReport? _report;
  List<SportEvent> _recentEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final report =
          await _attendanceService.getTeamReport(widget.teamId, limit: 40);
      final events = await _eventsService.getAllEvents(teamId: widget.teamId);
      final filtered = events
          .where(
            (e) =>
                (e.type == SportEventType.training ||
                    e.type == SportEventType.match) &&
                e.eventDate.isBefore(DateTime.now().add(const Duration(days: 1))),
          )
          .toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

      if (!mounted) return;
      setState(() {
        _report = report;
        _recentEvents = filtered.take(15).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AttendanceService.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Asistencias'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Por jugador'),
              Tab(text: 'Por sesión'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _playersTab(),
                  _sessionsTab(),
                ],
              ),
      ),
    );
  }

  Widget _playersTab() {
    final players = _report?.players ?? [];
    if (players.isEmpty) {
      return const Center(child: Text('Sin datos de asistencia'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: players.length,
        itemBuilder: (_, i) {
          final p = players[i];
          final total = p.total;
          final pct = total > 0 ? (p.present / total * 100).round() : 0;
          return Card(
            child: ListTile(
              title: Text(p.userName),
              subtitle: Text(
                'Presente ${p.present} · Ausente ${p.absent} · '
                'Justif. ${p.justified} · Sin marcar ${p.unmarked}',
              ),
              trailing: Text('$pct%'),
            ),
          );
        },
      ),
    );
  }

  Widget _sessionsTab() {
    if (_recentEvents.isEmpty) {
      return const Center(child: Text('No hay sesiones recientes'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _recentEvents.length,
        itemBuilder: (_, i) {
          final e = _recentEvents[i];
          return ListTile(
            leading: Icon(
              e.type == SportEventType.match
                  ? Icons.sports_soccer
                  : Icons.fitness_center,
            ),
            title: Text(e.title),
            subtitle: Text(e.typeDisplayName),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventAttendanceScreen(eventId: e.id),
                ),
              );
              _load();
            },
          );
        },
      ),
    );
  }
}

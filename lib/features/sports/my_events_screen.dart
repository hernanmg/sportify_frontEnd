import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/features/sports/event_detail_screen.dart';
import 'package:sportify_amateur/features/sports/social_event_expenses_screen.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final SportEventsService _eventsService = SportEventsService();
  List<SportEvent> _events = [];
  bool _loading = true;
  String? _error;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userIdStr = await AuthStorageService().getUserId();
      _userId = userIdStr != null ? int.tryParse(userIdStr) : null;
      final events = await _eventsService.getMyEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _respond(SportEvent event, String status) async {
    if (_userId == null) return;
    try {
      await _eventsService.updateParticipantResponse(
        event.id,
        _userId!,
        status,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed' ? 'Asistencia confirmada' : 'Invitación rechazada',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openEvent(SportEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EventDetailScreen(event: event),
      ),
    ).then((_) => _load());
  }

  void _openExpenses(SportEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SocialEventExpensesScreen(
          eventId: event.id,
          eventTitle: event.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis eventos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _events.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No tenés invitaciones a eventos.\nCuando te inviten a un evento social o entrenamiento, aparecerá acá.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final status = event.myParticipationStatus;
                          final isPending = status == 'pending' ||
                              status == 'no_response' ||
                              status == null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    event.type == SportEventType.social
                                        ? Icons.celebration
                                        : Icons.sports_soccer,
                                    color: event.type == SportEventType.social
                                        ? Colors.deepPurple
                                        : Colors.green,
                                  ),
                                  title: Text(event.title),
                                  subtitle: Text(
                                    '${event.teamName ?? 'Equipo'} · ${event.formattedDate}',
                                  ),
                                  trailing: _statusChip(context, status),
                                  onTap: () => _openEvent(event),
                                ),
                                if (isPending) ...[
                                  const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _respond(event, 'declined'),
                                            icon: const Icon(Icons.close),
                                            label: const Text('No voy'),
                                          ),
                                        ),
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () =>
                                                _respond(event, 'confirmed'),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Confirmo'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (event.type == SportEventType.social &&
                                    status != 'declined') ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      0,
                                      12,
                                      12,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openExpenses(event),
                                        icon: const Icon(
                                          Icons.account_balance_wallet_outlined,
                                        ),
                                        label: const Text('Gastos del evento'),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _statusChip(BuildContext context, String? status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'confirmed':
        return Chip(
          label: Text(
            'Confirmado',
            style: TextStyle(
              color: isDark ? Colors.green.shade900 : Colors.green.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          backgroundColor:
              isDark ? Colors.green.shade300 : Colors.green.shade100,
          side: BorderSide(
            color: isDark ? Colors.green.shade600 : Colors.green.shade300,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      case 'declined':
        return Chip(
          label: Text(
            'Rechazado',
            style: TextStyle(
              color: isDark ? Colors.red.shade900 : Colors.red.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          backgroundColor: isDark ? Colors.red.shade300 : Colors.red.shade100,
          side: BorderSide(
            color: isDark ? Colors.red.shade600 : Colors.red.shade300,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      default:
        return Chip(
          label: Text(
            'Pendiente',
            style: TextStyle(
              color: isDark ? Colors.orange.shade900 : Colors.orange.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          backgroundColor:
              isDark ? Colors.orange.shade300 : Colors.orange.shade100,
          side: BorderSide(
            color: isDark ? Colors.orange.shade700 : Colors.orange.shade300,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
    }
  }
}

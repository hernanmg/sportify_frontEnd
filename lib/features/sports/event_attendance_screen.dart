import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/attendance_service.dart';

class EventAttendanceScreen extends StatefulWidget {
  final int eventId;

  const EventAttendanceScreen({super.key, required this.eventId});

  @override
  State<EventAttendanceScreen> createState() => _EventAttendanceScreenState();
}

class _EventAttendanceScreenState extends State<EventAttendanceScreen> {
  final _service = AttendanceService();
  EventAttendanceView? _data;
  final Map<int, String?> _statusByUser = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getEventAttendance(widget.eventId);
      _statusByUser.clear();
      for (final p in data.participants) {
        _statusByUser[p.userId] = _validAttendanceStatus(p.status);
      }
      if (!mounted) return;
      setState(() {
        _data = data;
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

  String? _validAttendanceStatus(String? raw) {
    if (raw == 'present' || raw == 'absent' || raw == 'justified') {
      return raw;
    }
    return null;
  }

  Future<void> _save() async {
    final items = _statusByUser.entries
        .where((e) => e.value != null)
        .map(
          (e) => AttendanceUpdateItem(userId: e.key, status: e.value!),
        )
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marcá al menos un jugador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateEventAttendance(widget.eventId, items);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asistencia guardada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AttendanceService.errorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(data?.title ?? 'Asistencia'),
      ),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('Sin datos'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(data.eventDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La confirmación al evento aparece abajo. '
                      'Marcá presente, ausente o justificado después del entreno.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ...data.participants.map((p) => _row(p)),
                  ],
                ),
    );
  }

  Widget _row(AttendanceParticipantRow p) {
    final status = _statusByUser[p.userId];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.userName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              p.confirmationLabel,
              style: TextStyle(
                fontSize: 12,
                color: p.confirmationStatus == 'confirmed'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'present', label: Text('Presente')),
                ButtonSegment(value: 'absent', label: Text('Ausente')),
                ButtonSegment(value: 'justified', label: Text('Justif.')),
              ],
              selected: status != null ? {status} : {},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) {
                setState(() {
                  if (s.isEmpty) {
                    _statusByUser[p.userId] = null;
                  } else {
                    _statusByUser[p.userId] = s.first;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

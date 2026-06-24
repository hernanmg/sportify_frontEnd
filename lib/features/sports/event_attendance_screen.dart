import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/attendance_service.dart';
import 'package:sportify_amateur/core/services/offline_attendance_cache.dart';

class EventAttendanceScreen extends StatefulWidget {
  final int eventId;

  const EventAttendanceScreen({super.key, required this.eventId});

  @override
  State<EventAttendanceScreen> createState() => _EventAttendanceScreenState();
}

class _EventAttendanceScreenState extends State<EventAttendanceScreen>
    with WidgetsBindingObserver {
  final _service = AttendanceService();
  final _cache = OfflineAttendanceCache.instance;
  EventAttendanceView? _data;
  final Map<int, String?> _statusByUser = {};
  bool _loading = true;
  bool _saving = false;
  bool _usingCache = false;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trySyncPending();
    }
  }

  Future<void> _bootstrap() async {
    await _trySyncPending();
    await _load();
  }

  Future<void> _trySyncPending() async {
    final synced = await _cache.syncPending(_service);
    final pending = await _cache.pendingUpdates();
    if (!mounted) return;
    setState(() => _pendingSyncCount = pending.length);
    if (synced > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced == 1
                ? '1 lista de asistencia sincronizada'
                : '$synced listas sincronizadas',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Map<String, dynamic> _toCacheJson(EventAttendanceView data) {
    return {
      'eventId': data.eventId,
      'title': data.title,
      'type': data.type,
      'eventDate': data.eventDate.toIso8601String(),
      'participants': data.participants
          .map(
            (p) => {
              'userId': p.userId,
              'userName': p.userName,
              'status': p.status,
              'notes': p.notes,
              'confirmationStatus': p.confirmationStatus,
            },
          )
          .toList(),
    };
  }

  void _applyData(EventAttendanceView data, {required bool fromCache}) {
    _statusByUser.clear();
    for (final p in data.participants) {
      _statusByUser[p.userId] = _validAttendanceStatus(p.status);
    }
    setState(() {
      _data = data;
      _loading = false;
      _usingCache = fromCache;
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getEventAttendance(widget.eventId);
      await _cache.cacheEvent(widget.eventId, _toCacheJson(data));
      if (!mounted) return;
      _applyData(data, fromCache: false);
    } catch (e) {
      final cached = await _cache.getCachedEvent(widget.eventId);
      if (!mounted) return;
      if (cached != null) {
        _applyData(cached, fromCache: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin conexión — mostrando datos guardados en el teléfono'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AttendanceService.errorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validAttendanceStatus(String? raw) {
    if (raw == 'present' || raw == 'absent' || raw == 'justified') {
      return raw;
    }
    return null;
  }

  bool _isOfflineError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
    }
    return false;
  }

  Future<bool> _hasConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
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
      final online = await _hasConnectivity();
      if (!online) {
        throw DioException(
          requestOptions: RequestOptions(path: '/offline'),
          type: DioExceptionType.connectionError,
        );
      }
      await _service.updateEventAttendance(widget.eventId, items);
      if (_data != null) {
        await _cache.cacheStatusMap(widget.eventId, _statusByUser);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asistencia guardada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (_isOfflineError(e)) {
        await _cache.queuePendingUpdate(widget.eventId, items);
        await _cache.cacheStatusMap(widget.eventId, _statusByUser);
        final pending = await _cache.pendingUpdates();
        if (!mounted) return;
        setState(() {
          _usingCache = true;
          _pendingSyncCount = pending.length;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Guardado en el teléfono. Se subirá al servidor cuando haya señal.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
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
        actions: [
          if (_pendingSyncCount > 0)
            IconButton(
              tooltip: 'Sincronizar pendientes',
              onPressed: _saving ? null : _trySyncPending,
              icon: Badge(
                label: Text('$_pendingSyncCount'),
                child: const Icon(Icons.cloud_upload_outlined),
              ),
            ),
        ],
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
                    if (_usingCache || _pendingSyncCount > 0)
                      Card(
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: Icon(
                            Icons.wifi_off,
                            color: Colors.orange.shade800,
                          ),
                          title: const Text('Modo cancha'),
                          subtitle: Text(
                            _pendingSyncCount > 0
                                ? 'Hay $_pendingSyncCount cambio(s) esperando sincronizar.'
                                : 'Datos locales — conectate para actualizar desde el servidor.',
                          ),
                        ),
                      ),
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

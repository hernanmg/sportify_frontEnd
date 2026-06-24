import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/services/attendance_service.dart';

/// Cache local de asistencia para tomar lista en cancha sin señal.
class OfflineAttendanceCache {
  OfflineAttendanceCache._();
  static final OfflineAttendanceCache instance = OfflineAttendanceCache._();

  static const _eventPrefix = 'offline_attendance_event_';
  static const _pendingKey = 'offline_attendance_pending';

  Future<void> cacheEvent(int eventId, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_eventPrefix$eventId', jsonEncode(json));
  }

  Future<EventAttendanceView?> getCachedEvent(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_eventPrefix$eventId');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return EventAttendanceView.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheStatusMap(int eventId, Map<int, String?> statuses) async {
    final cached = await getCachedEvent(eventId);
    if (cached == null) return;
    final participants = cached.participants.map((p) {
      final status = statuses[p.userId];
      return {
        'userId': p.userId,
        'userName': p.userName,
        'status': status,
        'notes': p.notes,
        'confirmationStatus': p.confirmationStatus,
      };
    }).toList();
    await cacheEvent(eventId, {
      'eventId': cached.eventId,
      'title': cached.title,
      'type': cached.type,
      'eventDate': cached.eventDate.toIso8601String(),
      'participants': participants,
    });
  }

  Future<void> queuePendingUpdate(
    int eventId,
    List<AttendanceUpdateItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readPending(prefs);
    list.removeWhere((e) => e['eventId'] == eventId);
    list.add({
      'eventId': eventId,
      'items': items
          .map(
            (i) => {
              'userId': i.userId,
              'status': i.status,
              if (i.notes != null) 'notes': i.notes,
            },
          )
          .toList(),
      'queuedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_pendingKey, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> pendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    return _readPending(prefs);
  }

  Future<int> syncPending(AttendanceService service) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await _readPending(prefs);
    if (pending.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    var synced = 0;
    for (final entry in pending) {
      final eventId = entry['eventId'] as int;
      final rawItems = entry['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .map(
            (e) => AttendanceUpdateItem(
              userId: (e as Map)['userId'] as int,
              status: e['status'] as String,
              notes: e['notes']?.toString(),
            ),
          )
          .toList();
      try {
        await service.updateEventAttendance(eventId, items);
        synced++;
      } catch (_) {
        remaining.add(entry);
      }
    }
    await prefs.setString(_pendingKey, jsonEncode(remaining));
    return synced;
  }

  Future<List<Map<String, dynamic>>> _readPending(SharedPreferences prefs) async {
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}

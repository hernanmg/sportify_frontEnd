import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';

class AttendanceService {
  final Dio _dio = DioClient.instance;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        if (message is List) {
          return message.map((e) => e.toString()).join('\n');
        }
        return message.toString();
      }
    }
    return error.toString();
  }

  Future<EventAttendanceView> getEventAttendance(int eventId) async {
    final response = await _dio.get('/sport-events/$eventId/attendance');
    return EventAttendanceView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> updateEventAttendance(
    int eventId,
    List<AttendanceUpdateItem> items,
  ) async {
    await _dio.patch(
      '/sport-events/$eventId/attendance',
      data: {
        'items': items
            .map(
              (i) => {
                'userId': i.userId,
                'status': i.status,
                if (i.notes != null) 'notes': i.notes,
              },
            )
            .toList(),
      },
    );
  }

  Future<TeamAttendanceReport> getTeamReport(
    int teamId, {
    int? categoryId,
    int limit = 30,
  }) async {
    final response = await _dio.get(
      '/teams/$teamId/attendance-report',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        'limit': limit,
      },
    );
    return TeamAttendanceReport.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class AttendanceUpdateItem {
  final int userId;
  final String status;
  final String? notes;

  AttendanceUpdateItem({
    required this.userId,
    required this.status,
    this.notes,
  });
}

class EventAttendanceView {
  final int eventId;
  final String title;
  final String type;
  final DateTime eventDate;
  final List<AttendanceParticipantRow> participants;

  EventAttendanceView({
    required this.eventId,
    required this.title,
    required this.type,
    required this.eventDate,
    required this.participants,
  });

  factory EventAttendanceView.fromJson(Map<String, dynamic> json) {
    return EventAttendanceView(
      eventId: json['eventId'] as int,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      eventDate: DateTime.parse(json['eventDate'] as String),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map(
            (e) => AttendanceParticipantRow.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class AttendanceParticipantRow {
  final int userId;
  final String userName;
  final String? status;
  final String? notes;
  final String? confirmationStatus;

  AttendanceParticipantRow({
    required this.userId,
    required this.userName,
    this.status,
    this.notes,
    this.confirmationStatus,
  });

  factory AttendanceParticipantRow.fromJson(Map<String, dynamic> json) {
    return AttendanceParticipantRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
      confirmationStatus: json['confirmationStatus']?.toString(),
    );
  }

  String get confirmationLabel {
    switch (confirmationStatus) {
      case 'confirmed':
        return 'Confirmó asistencia';
      case 'declined':
        return 'Rechazó';
      case 'pending':
        return 'Pendiente de confirmar';
      default:
        return 'Sin respuesta';
    }
  }
}

class TeamAttendanceReport {
  final int teamId;
  final List<PlayerAttendanceSummary> players;

  TeamAttendanceReport({
    required this.teamId,
    required this.players,
  });

  factory TeamAttendanceReport.fromJson(Map<String, dynamic> json) {
    return TeamAttendanceReport(
      teamId: json['teamId'] as int,
      players: (json['players'] as List<dynamic>? ?? [])
          .map(
            (e) => PlayerAttendanceSummary.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class PlayerAttendanceSummary {
  final int userId;
  final String userName;
  final int present;
  final int absent;
  final int justified;
  final int unmarked;

  PlayerAttendanceSummary({
    required this.userId,
    required this.userName,
    required this.present,
    required this.absent,
    required this.justified,
    required this.unmarked,
  });

  factory PlayerAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return PlayerAttendanceSummary(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      justified: json['justified'] as int? ?? 0,
      unmarked: json['unmarked'] as int? ?? 0,
    );
  }

  int get total => present + absent + justified + unmarked;
  int get attended => present;
}

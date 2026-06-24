import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';

class TeamAdminService {
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

  Future<TeamAdminPanel> getAdminPanel(int teamId) async {
    final response = await _dio.get('/teams/$teamId/admin-panel');
    return TeamAdminPanel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class TeamAdminPanel {
  final int teamId;
  final List<DebtorRow> debtors;
  final List<PendingConfirmationEvent> pendingConfirmations;
  final NextConvocationSummary? nextConvocation;
  final LastSessionAttendance? lastSessionAttendance;
  final MonthFinance monthFinance;
  final List<UpcomingEventRow> upcomingEvents;

  TeamAdminPanel({
    required this.teamId,
    required this.debtors,
    required this.pendingConfirmations,
    this.nextConvocation,
    this.lastSessionAttendance,
    required this.monthFinance,
    required this.upcomingEvents,
  });

  factory TeamAdminPanel.fromJson(Map<String, dynamic> json) {
    return TeamAdminPanel(
      teamId: json['teamId'] as int,
      debtors: (json['debtors'] as List<dynamic>? ?? [])
          .map((e) => DebtorRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pendingConfirmations:
          (json['pendingConfirmations'] as List<dynamic>? ?? [])
              .map(
                (e) => PendingConfirmationEvent.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
      nextConvocation: json['nextConvocation'] != null
          ? NextConvocationSummary.fromJson(
              Map<String, dynamic>.from(json['nextConvocation'] as Map),
            )
          : null,
      lastSessionAttendance: json['lastSessionAttendance'] != null
          ? LastSessionAttendance.fromJson(
              Map<String, dynamic>.from(
                json['lastSessionAttendance'] as Map,
              ),
            )
          : null,
      monthFinance: MonthFinance.fromJson(
        Map<String, dynamic>.from(json['monthFinance'] as Map),
      ),
      upcomingEvents: (json['upcomingEvents'] as List<dynamic>? ?? [])
          .map(
            (e) => UpcomingEventRow.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class DebtorRow {
  final int userId;
  final String userName;
  final double balance;
  final int? jerseyNumber;

  DebtorRow({
    required this.userId,
    required this.userName,
    required this.balance,
    this.jerseyNumber,
  });

  factory DebtorRow.fromJson(Map<String, dynamic> json) {
    return DebtorRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
      balance: _toDouble(json['balance']),
      jerseyNumber: json['jerseyNumber'] as int?,
    );
  }
}

class PendingConfirmationEvent {
  final int eventId;
  final String title;
  final String type;
  final DateTime eventDate;
  final int pendingCount;
  final List<PendingPlayer> pending;

  PendingConfirmationEvent({
    required this.eventId,
    required this.title,
    required this.type,
    required this.eventDate,
    required this.pendingCount,
    required this.pending,
  });

  factory PendingConfirmationEvent.fromJson(Map<String, dynamic> json) {
    return PendingConfirmationEvent(
      eventId: json['eventId'] as int,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      eventDate: DateTime.parse(json['eventDate'] as String),
      pendingCount: json['pendingCount'] as int? ?? 0,
      pending: (json['pending'] as List<dynamic>? ?? [])
          .map((e) => PendingPlayer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class PendingPlayer {
  final int userId;
  final String userName;

  PendingPlayer({required this.userId, required this.userName});

  factory PendingPlayer.fromJson(Map<String, dynamic> json) {
    return PendingPlayer(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
    );
  }
}

class NextConvocationSummary {
  final int id;
  final String title;
  final String? opponentName;
  final DateTime eventDate;
  final int convoked;
  final int confirmed;
  final int pending;
  final int declined;

  NextConvocationSummary({
    required this.id,
    required this.title,
    this.opponentName,
    required this.eventDate,
    required this.convoked,
    required this.confirmed,
    required this.pending,
    required this.declined,
  });

  factory NextConvocationSummary.fromJson(Map<String, dynamic> json) {
    return NextConvocationSummary(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      opponentName: json['opponentName']?.toString(),
      eventDate: DateTime.parse(json['eventDate'] as String),
      convoked: json['convoked'] as int? ?? 0,
      confirmed: json['confirmed'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      declined: json['declined'] as int? ?? 0,
    );
  }
}

class LastSessionAttendance {
  final int eventId;
  final String title;
  final String type;
  final DateTime eventDate;
  final int present;
  final int absent;
  final int justified;
  final int unmarked;

  LastSessionAttendance({
    required this.eventId,
    required this.title,
    required this.type,
    required this.eventDate,
    required this.present,
    required this.absent,
    required this.justified,
    required this.unmarked,
  });

  factory LastSessionAttendance.fromJson(Map<String, dynamic> json) {
    return LastSessionAttendance(
      eventId: json['eventId'] as int,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      eventDate: DateTime.parse(json['eventDate'] as String),
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      justified: json['justified'] as int? ?? 0,
      unmarked: json['unmarked'] as int? ?? 0,
    );
  }
}

class MonthFinance {
  final double income;
  final double expenses;
  final double net;
  final double cashBalance;

  MonthFinance({
    required this.income,
    required this.expenses,
    required this.net,
    required this.cashBalance,
  });

  factory MonthFinance.fromJson(Map<String, dynamic> json) {
    return MonthFinance(
      income: _toDouble(json['income']),
      expenses: _toDouble(json['expenses']),
      net: _toDouble(json['net']),
      cashBalance: _toDouble(json['cashBalance']),
    );
  }
}

class UpcomingEventRow {
  final int id;
  final String title;
  final String type;
  final DateTime eventDate;

  UpcomingEventRow({
    required this.id,
    required this.title,
    required this.type,
    required this.eventDate,
  });

  factory UpcomingEventRow.fromJson(Map<String, dynamic> json) {
    return UpcomingEventRow(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      eventDate: DateTime.parse(json['eventDate'] as String),
    );
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

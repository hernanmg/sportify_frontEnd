import 'dart:ui' show Offset;

import 'package:sportify_amateur/models/board_stroke.dart';

class PostMatchPlayerOfMatch {
  final int userId;
  final String userName;
  final String? avatarUrl;
  final int? jerseyNumber;
  final double? officialScore;
  final double? teamAvgScore;
  final double? combinedScore;

  PostMatchPlayerOfMatch({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.jerseyNumber,
    this.officialScore,
    this.teamAvgScore,
    this.combinedScore,
  });

  factory PostMatchPlayerOfMatch.fromJson(Map<String, dynamic> json) {
    return PostMatchPlayerOfMatch(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? 'Jugador',
      avatarUrl: json['avatarUrl']?.toString(),
      jerseyNumber: json['jerseyNumber'] as int?,
      officialScore: _toDouble(json['officialScore']),
      teamAvgScore: _toDouble(json['teamAvgScore']),
      combinedScore: _toDouble(json['combinedScore']),
    );
  }

  double? get displayScore {
    if (combinedScore != null) return combinedScore;
    final parts = <double>[];
    if (teamAvgScore != null) parts.add(teamAvgScore!);
    if (officialScore != null) parts.add(officialScore!);
    if (parts.isEmpty) return null;
    final avg = parts.reduce((a, b) => a + b) / parts.length;
    return (avg * 10).round() / 10;
  }
}

class PostMatchPlayerRow {
  final int userId;
  final String userName;
  final String? avatarUrl;
  final int? jerseyNumber;
  final bool isConvoked;
  final bool? attended;
  final double? teamAvgScore;
  final int teamVoteCount;
  final double? officialScore;
  final int? myVote;

  PostMatchPlayerRow({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.jerseyNumber,
    required this.isConvoked,
    this.attended,
    this.teamAvgScore,
    required this.teamVoteCount,
    this.officialScore,
    this.myVote,
  });

  factory PostMatchPlayerRow.fromJson(Map<String, dynamic> json) {
    return PostMatchPlayerRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? 'Jugador',
      avatarUrl: json['avatarUrl']?.toString(),
      jerseyNumber: json['jerseyNumber'] as int?,
      isConvoked: json['isConvoked'] as bool? ?? true,
      attended: json['attended'] as bool?,
      teamAvgScore: _toDouble(json['teamAvgScore']),
      teamVoteCount: json['teamVoteCount'] as int? ?? 0,
      officialScore: _toDouble(json['officialScore']),
      myVote: json['myVote'] as int?,
    );
  }

  double? get displayScore {
    final parts = <double>[];
    if (teamAvgScore != null) parts.add(teamAvgScore!);
    if (officialScore != null) parts.add(officialScore!);
    if (parts.isEmpty) return null;
    final avg = parts.reduce((a, b) => a + b) / parts.length;
    return (avg * 10).round() / 10;
  }
}

class PostMatchLineupRow {
  final int userId;
  final String userName;
  final String? avatarUrl;
  final int? jerseyNumber;
  final String? playingPosition;
  final String role;
  final bool isStarter;
  final bool? attended;
  final bool confirmed;

  PostMatchLineupRow({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.jerseyNumber,
    this.playingPosition,
    required this.role,
    required this.isStarter,
    this.attended,
    this.confirmed = false,
  });

  factory PostMatchLineupRow.fromJson(Map<String, dynamic> json) {
    return PostMatchLineupRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? 'Jugador',
      avatarUrl: json['avatarUrl']?.toString(),
      jerseyNumber: json['jerseyNumber'] as int?,
      playingPosition: json['playingPosition']?.toString(),
      role: json['role']?.toString() ?? 'player',
      isStarter: json['isStarter'] as bool? ?? false,
      attended: json['attended'] as bool?,
      confirmed: _parseBool(json['confirmed']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'confirmed';
    }
    return false;
  }

  String get roleLabel {
    switch (role) {
      case 'substitute':
        return 'Suplente';
      case 'coach':
        return 'DT';
      case 'staff':
        return 'Staff';
      default:
        return 'Jugador';
    }
  }
}

class PostMatchStatsRow {
  final int userId;
  final String userName;
  final int? jerseyNumber;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int? minutesPlayed;

  PostMatchStatsRow({
    required this.userId,
    required this.userName,
    this.jerseyNumber,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    this.minutesPlayed,
  });

  factory PostMatchStatsRow.fromJson(Map<String, dynamic> json) {
    return PostMatchStatsRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? 'Jugador',
      jerseyNumber: json['jerseyNumber'] as int?,
      goals: json['goals'] as int? ?? 0,
      assists: json['assists'] as int? ?? 0,
      yellowCards: json['yellowCards'] as int? ?? 0,
      redCards: json['redCards'] as int? ?? 0,
      minutesPlayed: json['minutesPlayed'] as int?,
    );
  }
}

class PostMatchResult {
  final int? teamScore;
  final int? opponentScore;
  final bool isHomeMatch;

  PostMatchResult({
    this.teamScore,
    this.opponentScore,
    required this.isHomeMatch,
  });

  factory PostMatchResult.fromJson(Map<String, dynamic> json) {
    return PostMatchResult(
      teamScore: json['teamScore'] as int?,
      opponentScore: json['opponentScore'] as int?,
      isHomeMatch: json['isHomeMatch'] as bool? ?? true,
    );
  }

  String scoreLabel(String opponentName) {
    if (teamScore == null || opponentScore == null) return 'Sin resultado';
    final us = isHomeMatch ? teamScore : opponentScore;
    final them = isHomeMatch ? opponentScore : teamScore;
    return '$us - $them vs $opponentName';
  }
}

class PostMatchData {
  final int eventId;
  final String title;
  final int teamId;
  final DateTime eventDate;
  final String status;
  final String? opponentName;
  final bool canAccess;
  final bool postMatchOpen;
  final bool votingClosed;
  final bool canVote;
  final bool canManage;
  final PostMatchPlayerOfMatch? playerOfMatch;
  final List<PostMatchPlayerOfMatch> playerOfMatchTied;
  final List<PostMatchPlayerRow> targets;
  final int myVotesCount;
  final int votesExpected;
  final int currentUserId;
  final bool isCompleted;
  final PostMatchResult matchResult;
  final List<PostMatchLineupRow> lineup;
  final List<PostMatchStatsRow> stats;
  final String? formation;
  final Map<int, Offset> lineupSlots;
  final List<BoardStroke> boardStrokes;
  final String? reportText;
  final DateTime? reportUpdatedAt;
  final int? reportUpdatedByUserId;

  PostMatchData({
    required this.eventId,
    required this.title,
    required this.teamId,
    required this.eventDate,
    required this.status,
    this.opponentName,
    required this.canAccess,
    required this.postMatchOpen,
    required this.votingClosed,
    required this.canVote,
    required this.canManage,
    this.playerOfMatch,
    this.playerOfMatchTied = const [],
    required this.targets,
    required this.myVotesCount,
    required this.votesExpected,
    required this.currentUserId,
    required this.isCompleted,
    required this.matchResult,
    required this.lineup,
    required this.stats,
    this.formation,
    required this.lineupSlots,
    required this.boardStrokes,
    this.reportText,
    this.reportUpdatedAt,
    this.reportUpdatedByUserId,
  });

  factory PostMatchData.fromJson(Map<String, dynamic> json) {
    final pom = json['playerOfMatch'];
    final tiedRaw = json['playerOfMatchTied'];
    final report = json['report'];
    final reportMap = report is Map ? Map<String, dynamic>.from(report) : null;
    return PostMatchData(
      eventId: json['eventId'] as int,
      title: json['title']?.toString() ?? 'Partido',
      teamId: json['teamId'] as int,
      eventDate: DateTime.parse(json['eventDate'] as String),
      status: json['status']?.toString() ?? '',
      opponentName: json['opponentName']?.toString(),
      canAccess: json['canAccess'] as bool? ?? true,
      postMatchOpen: json['postMatchOpen'] as bool? ?? false,
      votingClosed: json['votingClosed'] as bool? ?? false,
      canVote: json['canVote'] as bool? ?? false,
      canManage: json['canManage'] as bool? ?? false,
      playerOfMatch: pom is Map<String, dynamic>
          ? PostMatchPlayerOfMatch.fromJson(pom)
          : null,
      playerOfMatchTied: tiedRaw is List
          ? tiedRaw
              .whereType<Map>()
              .map(
                (e) => PostMatchPlayerOfMatch.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      targets: (json['targets'] as List<dynamic>? ?? [])
          .map((e) => PostMatchPlayerRow.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      myVotesCount: json['myVotesCount'] as int? ?? 0,
      votesExpected: json['votesExpected'] as int? ?? 0,
      currentUserId: json['currentUserId'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      matchResult: PostMatchResult.fromJson(
        Map<String, dynamic>.from(
          (json['matchResult'] as Map?) ?? {'isHomeMatch': true},
        ),
      ),
      lineup: (json['lineup'] as List<dynamic>? ?? [])
          .map((e) => PostMatchLineupRow.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      stats: (json['stats'] as List<dynamic>? ?? [])
          .map((e) => PostMatchStatsRow.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      formation: json['formation']?.toString(),
      lineupSlots: _parseLineupSlots(json['lineupSlots']),
      boardStrokes: BoardStroke.listFromJson(json['boardStrokes']),
      reportText: reportMap?['text']?.toString(),
      reportUpdatedAt: reportMap != null && reportMap['updatedAt'] != null
          ? DateTime.tryParse(reportMap['updatedAt'].toString())
          : null,
      reportUpdatedByUserId: (reportMap?['updatedByUserId'] is int)
          ? (reportMap?['updatedByUserId'] as int)
          : int.tryParse('${reportMap?['updatedByUserId']}'),
    );
  }
}

Map<int, Offset> _parseLineupSlots(dynamic raw) {
  if (raw is! Map) return {};
  final out = <int, Offset>{};
  raw.forEach((key, value) {
    final uid = int.tryParse(key.toString());
    if (uid == null || value is! Map) return;
    final x = (value['x'] as num?)?.toDouble();
    final y = (value['y'] as num?)?.toDouble();
    if (x != null && y != null) {
      out[uid] = Offset(x, y);
    }
  });
  return out;
}

class VoteSheetResult {
  final bool success;
  final String? message;

  const VoteSheetResult({required this.success, this.message});
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

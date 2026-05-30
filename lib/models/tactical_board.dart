import 'dart:ui' show Offset;

import 'package:sportify_amateur/models/board_stroke.dart';

class TacticalBoard {
  final int id;
  final int teamId;
  final String name;
  final String? formation;
  final Map<int, Offset> lineupSlots;
  final List<BoardStroke> boardStrokes;
  final int createdByUserId;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  TacticalBoard({
    required this.id,
    required this.teamId,
    required this.name,
    this.formation,
    required this.lineupSlots,
    required this.boardStrokes,
    required this.createdByUserId,
    this.shareToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TacticalBoard.fromJson(Map<String, dynamic> json) {
    return TacticalBoard(
      id: json['id'] as int,
      teamId: json['teamId'] as int,
      name: json['name']?.toString() ?? 'Táctica',
      formation: json['formation']?.toString(),
      lineupSlots: _parseSlots(json['lineupSlots']),
      boardStrokes: BoardStroke.listFromJson(json['boardStrokes']),
      createdByUserId: json['createdByUserId'] as int? ?? 0,
      shareToken: json['shareToken']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static Map<int, Offset> _parseSlots(dynamic raw) {
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

  Map<String, dynamic> toCreatePayload({
    required String name,
    String? formation,
    Map<int, Offset>? slots,
    List<BoardStroke>? strokes,
  }) {
    final slotsPayload = (slots ?? lineupSlots).map(
      (k, v) => MapEntry(
        k.toString(),
        {'x': v.dx, 'y': v.dy},
      ),
    );
    return {
      'name': name,
      if (formation != null) 'formation': formation,
      'lineupSlots': slotsPayload,
      'boardStrokes': (strokes ?? boardStrokes).map((s) => s.toJson()).toList(),
    };
  }
}

class TacticalBoardShareInfo {
  final String shareToken;
  final String sharePath;

  TacticalBoardShareInfo({
    required this.shareToken,
    required this.sharePath,
  });

  factory TacticalBoardShareInfo.fromJson(Map<String, dynamic> json) {
    return TacticalBoardShareInfo(
      shareToken: json['shareToken']?.toString() ?? '',
      sharePath: json['sharePath']?.toString() ?? '',
    );
  }

  String fullUrl(String apiBaseUrl) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final path = sharePath.startsWith('/') ? sharePath : '/$sharePath';
    return '$base$path';
  }
}

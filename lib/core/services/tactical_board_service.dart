import 'dart:ui' show Offset;

import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/board_stroke.dart';
import 'package:sportify_amateur/models/tactical_board.dart';

class TacticalBoardService {
  final Dio _dio = DioClient.instance;

  Future<List<TacticalBoard>> listByTeam(int teamId) async {
    final res = await _dio.get('/teams/$teamId/tactical-boards');
    final list = res.data as List<dynamic>? ?? [];
    return list
        .map((e) => TacticalBoard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<TacticalBoard> create(
    int teamId, {
    required String name,
    String? formation,
    required Map<String, dynamic> lineupSlots,
    required List<Map<String, dynamic>> boardStrokes,
  }) async {
    final res = await _dio.post(
      '/teams/$teamId/tactical-boards',
      data: {
        'name': name,
        if (formation != null) 'formation': formation,
        'lineupSlots': lineupSlots,
        'boardStrokes': boardStrokes,
      },
    );
    return TacticalBoard.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<TacticalBoard> update(
    int teamId,
    int boardId, {
    String? name,
    String? formation,
    Map<String, dynamic>? lineupSlots,
    List<Map<String, dynamic>>? boardStrokes,
  }) async {
    final res = await _dio.patch(
      '/teams/$teamId/tactical-boards/$boardId',
      data: {
        if (name != null) 'name': name,
        if (formation != null) 'formation': formation,
        if (lineupSlots != null) 'lineupSlots': lineupSlots,
        if (boardStrokes != null) 'boardStrokes': boardStrokes,
      },
    );
    return TacticalBoard.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> delete(int teamId, int boardId) async {
    await _dio.delete('/teams/$teamId/tactical-boards/$boardId');
  }

  Future<TacticalBoardShareInfo> enableShare(int teamId, int boardId) async {
    final res = await _dio.post(
      '/teams/$teamId/tactical-boards/$boardId/share',
    );
    return TacticalBoardShareInfo.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }

  Future<TacticalBoard> getShared(String token) async {
    final res = await _dio.get('/tactical-boards/shared/$token');
    return TacticalBoard.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      return e.message ?? 'Error de red';
    }
    return e.toString();
  }

  static Map<String, dynamic> slotsToPayload(Map<int, Offset> slots) {
    return slots.map(
      (k, v) => MapEntry(
        k.toString(),
        {'x': v.dx, 'y': v.dy},
      ),
    );
  }

  static List<Map<String, dynamic>> strokesToPayload(
    List<BoardStroke> strokes,
  ) =>
      strokes.map((s) => s.toJson()).toList();
}

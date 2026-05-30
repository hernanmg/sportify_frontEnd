import 'dart:ui' show Offset;

import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/board_stroke.dart';
import 'package:sportify_amateur/models/post_match.dart';

class PostMatchService {
  final Dio _dio = DioClient.instance;

  Future<PostMatchData> getPostMatch(int eventId) async {
    final response = await _dio.get('/sport-events/$eventId/post-match');
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> submitVotes(
    int eventId,
    List<Map<String, int>> ratings,
  ) async {
    final response = await _dio.post(
      '/sport-events/$eventId/post-match/votes',
      data: {'ratings': ratings},
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> setOfficialRatings(
    int eventId, {
    required List<Map<String, int>> ratings,
    int? playerOfMatchUserId,
  }) async {
    final response = await _dio.put(
      '/sport-events/$eventId/post-match/official',
      data: {
        'ratings': ratings,
        if (playerOfMatchUserId != null)
          'playerOfMatchUserId': playerOfMatchUserId,
      },
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> closeVoting(int eventId) async {
    final response = await _dio.post(
      '/sport-events/$eventId/post-match/close-voting',
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> updateReport(
    int eventId, {
    required String? text,
  }) async {
    final response = await _dio.patch(
      '/sport-events/$eventId/post-match/report',
      data: {'text': text},
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> updateAttendance(
    int eventId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _dio.patch(
      '/sport-events/$eventId/post-match/attendance',
      data: {'items': items},
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> updateLineup(
    int eventId, {
    required List<Map<String, dynamic>> items,
    String? formation,
    Map<int, Offset>? lineupSlots,
    List<BoardStroke>? boardStrokes,
  }) async {
    final slotsPayload = lineupSlots?.map(
      (k, v) => MapEntry(
        k.toString(),
        {'x': v.dx, 'y': v.dy},
      ),
    );
    final response = await _dio.patch(
      '/sport-events/$eventId/post-match/lineup',
      data: {
        'items': items,
        if (formation != null) 'formation': formation,
        if (slotsPayload != null) 'lineupSlots': slotsPayload,
        if (boardStrokes != null)
          'boardStrokes': boardStrokes.map((s) => s.toJson()).toList(),
      },
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> updateStats(
    int eventId, {
    int? teamScore,
    int? opponentScore,
    required List<Map<String, dynamic>> players,
  }) async {
    final response = await _dio.patch(
      '/sport-events/$eventId/post-match/stats',
      data: {
        if (teamScore != null) 'teamScore': teamScore,
        if (opponentScore != null) 'opponentScore': opponentScore,
        'players': players,
      },
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<PostMatchData> completeMatch(
    int eventId, {
    int? teamScore,
    int? opponentScore,
  }) async {
    final response = await _dio.post(
      '/sport-events/$eventId/post-match/complete',
      data: {
        if (teamScore != null) 'teamScore': teamScore,
        if (opponentScore != null) 'opponentScore': opponentScore,
      },
    );
    return PostMatchData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      if (e.response?.statusCode == 500) {
        return 'Error del servidor (¿migración 015 aplicada?)';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Sin conexión con el servidor';
      }
    }
    return e.toString();
  }
}

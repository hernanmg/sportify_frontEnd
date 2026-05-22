import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
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

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
    }
    return e.toString();
  }
}

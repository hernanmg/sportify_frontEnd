import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/player_eligibility.dart';

class PlayerStatusService {
  final Dio _dio = DioClient.instance;

  Future<List<PlayerEligibility>> getTeamEligibility(
    int teamId, {
    String? season,
  }) async {
    final response = await _dio.get(
      '/teams/$teamId/player-status',
      queryParameters: {
        if (season != null) 'season': season,
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => PlayerEligibility.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> createImpediment(
    int teamId, {
    required int userId,
    required String impedimentType,
    required String startDate,
    int? durationDays,
    String? description,
  }) async {
    await _dio.post(
      '/teams/$teamId/player-status/impediments',
      data: {
        'userId': userId,
        'impedimentType': impedimentType,
        'startDate': startDate,
        if (durationDays != null) 'durationDays': durationDays,
        if (description != null) 'description': description,
      },
    );
  }

  Future<void> clearImpediment(int teamId, int impedimentId) async {
    await _dio.delete(
      '/teams/$teamId/player-status/impediments/$impedimentId',
    );
  }

  Future<void> setFeeOverride(
    int teamId,
    int userId, {
    String? reason,
  }) async {
    await _dio.post(
      '/teams/$teamId/player-status/fee-override/$userId',
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<void> clearFeeOverride(int teamId, int userId) async {
    await _dio.delete(
      '/teams/$teamId/player-status/fee-override/$userId',
    );
  }

  Future<List<Map<String, dynamic>>> getAuditLog(
    int teamId, {
    int? userId,
  }) async {
    final response = await _dio.get(
      '/teams/$teamId/player-status/audit',
      queryParameters: {if (userId != null) 'userId': userId},
    );
    return (response.data as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

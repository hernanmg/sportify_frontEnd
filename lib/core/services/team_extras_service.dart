import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/services/team_service.dart';

class TeamExtrasService {
  final Dio _dio = DioClient.instance;

  static String errorMessage(Object error) => TeamService.errorMessage(error);

  Future<Map<String, dynamic>> getReports(
    int teamId, {
    String? season,
  }) async {
    final response = await _dio.get(
      '/teams/$teamId/reports',
      queryParameters: season != null ? {'season': season} : null,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getSponsors(int teamId) async {
    final response = await _dio.get('/teams/$teamId/sponsors');
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createSponsor(
    int teamId, {
    required String name,
    String? description,
    String? website,
    double? amountContributed,
  }) async {
    final response = await _dio.post(
      '/teams/$teamId/sponsors',
      data: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (website != null && website.isNotEmpty) 'website': website,
        if (amountContributed != null) 'amountContributed': amountContributed,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> removeSponsor(int teamId, int sponsorId) async {
    await _dio.delete('/teams/$teamId/sponsors/$sponsorId');
  }

  Future<List<Map<String, dynamic>>> getAuditLog(int teamId) async {
    final response = await _dio.get('/teams/$teamId/audit-log');
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/team_calendar_item.dart';

class TeamCalendarService {
  final Dio _dio = DioClient.instance;

  Future<TeamCalendarResponse> getTeamCalendar({
    required int teamId,
    required DateTime from,
    required DateTime to,
    String kinds = 'all',
  }) async {
    final response = await _dio.get(
      '/teams/$teamId/calendar',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'kinds': kinds,
      },
    );
    if (response.statusCode == 200) {
      return TeamCalendarResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    throw Exception('Error al cargar calendario');
  }
}

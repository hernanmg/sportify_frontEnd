import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/sport_position.dart';

class SportPositionsService {
  final Dio _dio = DioClient.instance;

  static final List<SportPosition> _fallback = [
    SportPosition(id: 0, sportId: 0, code: 'goalkeeper', label: 'Arquero'),
    SportPosition(id: 0, sportId: 0, code: 'defender', label: 'Defensor'),
    SportPosition(id: 0, sportId: 0, code: 'midfielder', label: 'Mediocampo'),
    SportPosition(id: 0, sportId: 0, code: 'forward', label: 'Delantero'),
    SportPosition(id: 0, sportId: 0, code: 'player', label: 'Jugador'),
  ];

  Future<List<SportPosition>> getBySportId(int sportId) async {
    try {
      final response = await _dio.get('/sports/$sportId/positions');
      final data = response.data as List<dynamic>;
      if (data.isEmpty) return _fallback;
      return data
          .map((e) => SportPosition.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return _fallback;
    }
  }
}

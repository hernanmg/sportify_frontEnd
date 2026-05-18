import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/convocation_template.dart';

class ConvocationTemplateService {
  final Dio _dio = DioClient.instance;

  Future<List<ConvocationTemplate>> list(int teamId) async {
    final response = await _dio.get('/teams/$teamId/convocation-templates');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => ConvocationTemplate.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<ConvocationTemplate> create(
    int teamId, {
    required String name,
    List<int>? defaultParticipantUserIds,
  }) async {
    final response = await _dio.post(
      '/teams/$teamId/convocation-templates',
      data: {
        'name': name,
        if (defaultParticipantUserIds != null)
          'defaultParticipantUserIds': defaultParticipantUserIds,
      },
    );
    return ConvocationTemplate.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> delete(int teamId, int templateId) async {
    await _dio.delete('/teams/$teamId/convocation-templates/$templateId');
  }
}

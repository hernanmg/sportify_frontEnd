import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/user_profile.dart';

class UserProfileService {
  final Dio _dio = DioClient.instance;

  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return UserProfile.fromJson(data);
      }
      throw Exception('Error al obtener perfil');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put('/users/profile', data: profileData);
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return UserProfile.fromJson(data);
      }
      throw Exception('Error al actualizar perfil');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> getProfileCompletion() async {
    try {
      final response = await _dio.get('/users/profile/completion');
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        return <String, dynamic>{
          'completion': data['completion'] ?? 0,
          'missingFields': List<String>.from(data['missingFields'] ?? []),
        };
      }
      throw Exception('Error al obtener progreso del perfil');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Métodos de utilidad para el onboarding
  Future<void> updateBasicInfo({
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? fechaNacimiento,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (phone != null) data['phone'] = phone;
    if (fechaNacimiento != null)
      data['fechaNacimiento'] = fechaNacimiento.toIso8601String();
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

    await updateProfile(data);
  }

  Future<void> updateLocationInfo({
    String? ciudad,
    String? provincia,
    String? pais,
  }) async {
    final data = <String, dynamic>{};
    if (ciudad != null) data['ciudad'] = ciudad;
    if (provincia != null) data['provincia'] = provincia;
    if (pais != null) data['pais'] = pais;

    await updateProfile(data);
  }

  Future<void> updateSportsInfo({
    String? bio,
    String? experienciaDeportiva,
  }) async {
    final data = <String, dynamic>{};
    if (bio != null) data['bio'] = bio;
    if (experienciaDeportiva != null)
      data['experienciaDeportiva'] = experienciaDeportiva;

    await updateProfile(data);
  }

  Future<void> completeOnboarding() async {
    await updateProfile({
      'estadoRegistro': 'completed',
      'profileCompletion': 100,
    });
  }
}

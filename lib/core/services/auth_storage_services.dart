import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:http/http.dart' as http;

class AuthStorageService {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  //final String backendUrl = AppConfig.apiBaseUrl;
  static String get backendUrl => AppConfig.apiBaseUrl;
  // Guarda el token en almacenamiento
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString("authToken", token);
    await secureStorage.write(key: 'authToken', value: accessToken);
    await secureStorage.write(key: 'refreshToken', value: refreshToken);
  }

  // Obtiene el token guardado
  Future<String?> getToken() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // return prefs.getString("authToken");
    return await secureStorage.read(key: 'authToken');
  }

  // Borra el token guardado
  Future<void> clearStoredToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("authToken");
  }

  Future<String?> _getRefreshToken() async {
    return await secureStorage.read(key: 'refreshToken');
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'authToken');
    await secureStorage.delete(key: 'refreshToken');
    await secureStorage.delete(key: 'role');
    await secureStorage.delete(key: 'userId');
    await secureStorage.delete(key: 'userName');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> renewToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token available');

    final response = await http.post(
      Uri.parse('$backendUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];
      await saveTokens(newAccessToken, newRefreshToken);
    } else {
      throw Exception('Error al renovar el token');
    }
  }

  // Obtiene el rol del usuario guardado
  Future<String?> getRole() async {
    return await secureStorage.read(key: 'role');
  }

  // Obtiene el userId guardado
  Future<String?> getUserId() async {
    return await secureStorage.read(key: 'userId');
  }

  // Obtiene el userName guardado
  Future<String?> getUserName() async {
    return await secureStorage.read(key: 'userName');
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/user_profile_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

class AuthService {
  //final String backendUrl = AppConfig.apiBaseUrl;
  static String get backendUrl => AppConfig.apiBaseUrl;
  final AuthStorageService storageService = AuthStorageService();
  final UserProfileService profileService = UserProfileService();
  final secureStorage = FlutterSecureStorage();
  final Dio _dio = DioClient.instance;

  Future<bool> signInWithGoogle() async {
    try {
      print('Inicia el proceso de autenticación con Google');
      print('kIsWeb: $kIsWeb');
      print('kDebugMode: $kDebugMode');
      print('backendUrl: $backendUrl');

      GoogleSignIn googleSignIn;

      if (kIsWeb) {
        // 🔑 En Web hay que pasar el clientId explícito
        googleSignIn = GoogleSignIn(
          clientId: AppConfig.googleClientId,
        );
      } else {
        // En Android/iOS se usa la configuración de Firebase/Google Console
        googleSignIn = GoogleSignIn();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      print('googleUser');
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return false;
      }

      print('Obtén el token de autenticación de Google');
      final googleAuth = await googleUser.authentication;

      // print(googleAuth);

      // Envía el token al backend
      final String finalUrl = kIsWeb ? 'http://localhost:3000' : backendUrl;
      print('URL final: $finalUrl/auth/google/token');
      final response = await http.post(
        Uri.parse('$finalUrl/auth/google/token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'accessToken': googleAuth.accessToken,
        }),
      );

      if (response.statusCode == 200) {
        // Procesar la respuesta del backend y guardar tokens
        final data = json.decode(response.body);
        final token = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final userId = data['userId'];
        final userName = data['userName'];
        final role = data['role'];

        // Guardar los tokens y datos del usuario en almacenamiento seguro
        await secureStorage.write(key: 'authToken', value: token);
        await secureStorage.write(key: 'refreshToken', value: refreshToken);
        await secureStorage.write(key: 'userId', value: userId.toString());
        await secureStorage.write(key: 'userName', value: userName);
        await secureStorage.write(key: 'role', value: role);

        print('Tokens guardados exitosamente');
        print('userId: $userId, userName: $userName, role: $role');

        return true;
      } else {
        print('Error en autenticación con Google: ${response.body}');
        return false;
      }
    } catch (e, st) {
      print('Error en autenticación con Google: $e');
      print(st);
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final response = await http.post(
          Uri.parse('$backendUrl/facebook-login'),
          body: jsonEncode({'token': result.accessToken!.tokenString}),
          headers: {'Content-Type': 'application/json'},
        );

        // Verifica si la respuesta del servidor es exitosa
        if (response.statusCode == 200) {
          return true; // Autenticación exitosa
        } else {
          print('Error en autenticación con Facebook: ${response.body}');
          return false; // Error en la autenticación
        }
      } else {
        print('Error en el inicio de sesión de Facebook: ${result.status}');
        return false; // El usuario canceló el inicio de sesión o hubo otro error
      }
    } catch (e) {
      print('Error en autenticación con Facebook: $e');
      return false; // Error en la solicitud
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      // final response = await http.post(
      //   Uri.parse('$backendUrl/login'),
      //   body: jsonEncode({'userName': email, 'password': password}),
      //   headers: {'Content-Type': 'application/json'},
      // );
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // final data = json.decode(response.data);
        final token = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];
        final rol = response.data['role'];

        // Guardar el token y el role en almacenamiento seguro
        await secureStorage.write(key: 'authToken', value: token);
        await secureStorage.write(key: 'refreshToken', value: refreshToken);
        await secureStorage.write(key: 'role', value: rol);

        return true;
      } else {
        return false;
      }

      // await Future.delayed(Duration(seconds: 1)); // Simula un retraso de red
      // final response = {
      //   'statusCode': 200,
      //   'body': jsonEncode({'message': 'Login successful'}),
      // };
      // // Verifica si la respuesta del servidor es exitosa
      // if (response['statusCode'] == 200) { //if (response.statusCode == 200) {
      //   return true; // Autenticación exitosa
      // } else {
      //   // print('Error en autenticación con Email: ${response.body}');
      //   return false; // Error en la autenticación
      // }
    } catch (e) {
      print('Error en autenticación con Email: $e');
      return false; // Error en la solicitud
    }
  }

  Future<void> signOut() async {
    await storageService.logout();

    // Aquí puedes añadir otros pasos para cerrar sesión, como desactivar sesiones activas o limpiar variables en memoria
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await storageService.getHeaders();
      final response = await http.get(
        Uri.parse('$backendUrl/users/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Token expirado, intentar renovar
        await storageService.renewToken();
        return getProfile(); // Reintentar la solicitud
      } else {
        throw Exception('Error al obtener el perfil');
      }
    } catch (e) {
      throw Exception('Error general: $e');
    }
  }

  Future<String?> getUserRole() async {
    final profile = await getProfile();
    return profile[
        'role']; // Asumiendo que el backend incluye "role" en el perfil
  }

  Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      final token = await storageService.getToken();
      if (token == null) {
        return {'isAuthenticated': false, 'needsOnboarding': false};
      }

      // Verificar si el perfil necesita onboarding
      final profileCompletion = await profileService.getProfileCompletion();
      final completion = profileCompletion['completion'] as int;

      return {
        'isAuthenticated': true,
        'needsOnboarding':
            completion < 80, // Si el perfil está menos del 80% completo
        'profileCompletion': completion,
        'missingFields': profileCompletion['missingFields'],
      };
    } catch (e) {
      print('Error checking auth status: $e');
      return {'isAuthenticated': false, 'needsOnboarding': false};
    }
  }
}

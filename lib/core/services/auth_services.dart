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

class AuthService {
  final String backendUrl = AppConfig.apiBaseUrl;
  final AuthStorageService storageService = AuthStorageService();
  final secureStorage = FlutterSecureStorage();
  final Dio _dio = DioClient.instance;
  
  Future<bool> signInWithGoogle() async {
    try {
      // Inicia el proceso de autenticación con Google
      print('Inicia el proceso de autenticación con Google');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      print('googleUser');
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return false;
      }

      // Obtén el token de autenticación de Google
      print('Obtén el token de autenticación de Google');

      final googleAuth = await googleUser.authentication;

      print(googleAuth);
      // print('Envía el token al backend');

      // // Envía el token al backend
      final response = await http.get(
        Uri.parse('$backendUrl/google'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${googleAuth.accessToken}',
        },
      );
      // Verifica si la respuesta del servidor es exitosa
      if (response.statusCode == 200) {
        // Manejo de respuesta exitosa (puedes hacer otras validaciones aquí si es necesario)
        return true;
      } else {
        // Manejo de error del servidor
        print('Error en autenticación con Google: ${response.body}');
        return false;
      }
    } catch (e) {
      // Manejo de errores en la solicitud
      print('Error en autenticación con Google: $e');
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
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';
import 'package:sportify_amateur/core/services/push_registration_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/core/services/user_profile_service.dart';
import 'package:flutter/material.dart';
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

        await PushRegistrationService.instance.registerAfterLogin();
        NotificationService().startBackgroundSync();

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

  static bool _isConnectionTimeout(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  static String loginErrorMessage(Object error) {
    if (error is DioException) {
      if (_isConnectionTimeout(error)) {
        return 'El servidor tardó en responder (Render puede estar despertando). '
            'Esperá unos segundos e intentá de nuevo.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join('\n');
        return msg.toString();
      }
      if (error.response?.statusCode == 401) {
        return 'Email o contraseña incorrectos';
      }
    }
    return error.toString();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    print('🔐 Iniciando login con email: $email');
    print('🌐 URL base configurada: ${_dio.options.baseUrl}');

    final payload = {
      'email': email.trim(),
      'password': password,
    };
    Response<dynamic> response;
    try {
      response = await _dio.post('/auth/login', data: payload);
    } on DioException catch (e) {
      if (_isConnectionTimeout(e)) {
        print('⏳ Cold start / red lenta; reintentando login…');
        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          response = await _dio.post('/auth/login', data: payload);
        } on DioException catch (retryError) {
          throw Exception(loginErrorMessage(retryError));
        }
      } else {
        throw Exception(loginErrorMessage(e));
      }
    }

    print('📡 Respuesta del servidor: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('No se pudo iniciar sesión (${response.statusCode})');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    final token = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    if (token == null || token.isEmpty || refreshToken == null) {
      throw Exception('Respuesta del servidor incompleta');
    }

    await secureStorage.write(key: 'authToken', value: token);
    await secureStorage.write(key: 'refreshToken', value: refreshToken);
    await secureStorage.write(key: 'userId', value: '${data['userId']}');
    await secureStorage.write(key: 'userName', value: data['userName']?.toString());
    await secureStorage.write(key: 'role', value: data['role']?.toString());

    print('✅ Login OK — rol: ${data['role']}');

    try {
      await PushRegistrationService.instance.registerAfterLogin();
      NotificationService().startBackgroundSync();
    } catch (e) {
      print('FCM post-login (no bloquea): $e');
    }

    return true;
  }

  Future<void> signOut() async {
    await PushRegistrationService.instance.unregisterOnLogout();
    NotificationService().disconnectOnLogout();
    await storageService.logout();
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
        try {
          await storageService.renewToken();
          return getProfile();
        } catch (_) {
          throw Exception('Sesión expirada');
        }
      } else {
        throw Exception('Error al obtener el perfil');
      }
    } catch (e) {
      throw Exception('Error general: $e');
    }
  }

  Future<String?> getUserRole() async {
    final profile = await getProfile();
    return profile['role']?.toString();
  }

  /// Actualiza el rol local si el servidor reporta uno distinto (p. ej. tras fix en BD).
  Future<String?> syncStoredRoleFromServer() async {
    try {
      final profile = await profileService.getProfile();
      final serverRole = profile.role?.trim();
      if (serverRole == null || serverRole.isEmpty) {
        return await storageService.getRole();
      }
      final local = await storageService.getRole();
      if (local != serverRole) {
        await storageService.saveRole(serverRole);
      }
      return serverRole;
    } catch (_) {
      return await storageService.getRole();
    }
  }

  Future<Map<String, dynamic>> checkAuthStatus() async {
    try {
      final token = await storageService.getToken();
      if (token == null) {
        return {'isAuthenticated': false, 'needsOnboarding': false};
      }

      final profile = await profileService.getProfile();
      final completion = profile.profileCompletion;
      final onboardingDone = profile.estadoRegistro == 'completed';
      var role = profile.role?.trim();
      if (role == null || role.isEmpty) {
        role = await storageService.getRole();
      } else {
        final local = await storageService.getRole();
        if (local != role) {
          await storageService.saveRole(role);
        }
      }
      const staffRoles = {'dt', 'super_admin', 'manager', 'admin'};
      final isStaff = staffRoles.contains(role);
      final hasBasicIdentity = (profile.firstName?.trim().isNotEmpty ?? false) &&
          (profile.lastName?.trim().isNotEmpty ?? false);

      var hasTeams = false;
      try {
        final teams = await TeamService().getMyTeams();
        hasTeams = teams.isNotEmpty;
      } catch (_) {}

      final isPlatformAdmin =
          role == 'super_admin' || role == 'manager' || role == 'admin';
      final skippedTeamSetup = await storageService.hasSkippedTeamSetup();

      var needsOnboarding = !onboardingDone && completion < 80;
      if (hasTeams) {
        needsOnboarding = false;
      } else if (hasBasicIdentity) {
        // Con nombre/apellido puede usar la app y completar perfil en /profile/info.
        needsOnboarding = false;
      }

      // Solo DT debe unirse con código; platform admin crea equipos desde Gestión.
      var needsTeamSetup = role == 'dt' && !hasTeams && !skippedTeamSetup;

      return {
        'isAuthenticated': true,
        'needsOnboarding': needsOnboarding,
        'needsTeamSetup': needsTeamSetup,
        'isPlatformAdmin': isPlatformAdmin,
        'isStaffRole': isStaff,
        'profileCompletion': completion,
        'estadoRegistro': profile.estadoRegistro,
        'role': role,
      };
    } catch (e) {
      print('Error checking auth status: $e');
      return {'isAuthenticated': false, 'needsOnboarding': false};
    }
  }

  /// Navegación post-login/registro según onboarding y alta en equipo.
  Future<void> navigateAfterAuth(BuildContext context) async {
    final authStatus = await checkAuthStatus();
    if (!context.mounted) return;
    if (authStatus['needsTeamSetup'] == true) {
      Navigator.pushReplacementNamed(context, '/staff-team-setup');
    } else if (authStatus['needsOnboarding'] == true) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      print('📝 Iniciando registro con email: $email');
      print('🌐 URL base configurada: ${_dio.options.baseUrl}');

      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
      });

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📦 Datos recibidos: ${response.data}');

      if (response.statusCode == 201) {
        // Procesar la respuesta del backend y guardar tokens
        final data = Map<String, dynamic>.from(response.data as Map);
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

        print('✅ Usuario registrado y tokens guardados exitosamente');
        print('👤 Nuevo usuario: $userName, Rol: $role');

        await PushRegistrationService.instance.registerAfterLogin();
        NotificationService().startBackgroundSync();

        return true;
      } else {
        print('❌ Error de registro: ${response.data}');
        return false;
      }
    } catch (e) {
      print('💥 Error en registro con Email: $e');
      return false;
    }
  }
}

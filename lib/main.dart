import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/common/app_config.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/features/auth/login.dart';
import 'package:sportify_amateur/features/auth/user_login.dart';
import 'package:sportify_amateur/features/dashboard/dashboard_screen.dart';
import 'package:sportify_amateur/features/dashboard/secondaryHome_screen.dart';
import 'package:sportify_amateur/features/roles/roles_screen.dart';
import 'package:sportify_amateur/features/users/users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = AuthStorageService();
  print('Base URL: ${AppConfig.apiBaseUrl}');
  // Limpia el token al iniciar la app (solo para pruebas)
  await storageService.clearStoredToken();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportify Amateur',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => const UserLoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/secondary': (context) => const SecondaryHomeScreen(),
        '/roles': (context) => const RolesScreen(),
        '/users': (context) => const UsersScreen(),
        '/game-stats': (context) => const Scaffold(
              body: Center(child: Text('Estadísticas de Juego')),
            ),
      },
    );
  }
}

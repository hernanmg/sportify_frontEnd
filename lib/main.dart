import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/common/themes_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/features/auth/login.dart';
import 'package:sportify_amateur/features/auth/user_login.dart';
import 'package:sportify_amateur/features/auth/register_screen.dart';
import 'package:sportify_amateur/features/dashboard/dashboard_screen.dart';
import 'package:sportify_amateur/features/profile/profile_screen.dart';
import 'package:sportify_amateur/features/profile/profile_info_screen.dart';
import 'package:sportify_amateur/features/profile/security_screen.dart';
import 'package:sportify_amateur/features/profile/admin_config_screen.dart';
import 'package:sportify_amateur/features/admin/admin_users_screen.dart';
import 'package:sportify_amateur/features/admin/deleted_users_screen.dart';
import 'package:sportify_amateur/features/permissions/permissions_screen.dart';
import 'package:sportify_amateur/features/sports/roster_management_screen.dart';
import 'package:sportify_amateur/features/teams/teams_management_screen.dart';
import 'package:sportify_amateur/features/onboarding/onboarding_wizard.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';
import 'package:sportify_amateur/features/dashboard/secondaryHome_screen.dart';
import 'package:sportify_amateur/features/gameStats/comparePlayerStats_screen.dart';
import 'package:sportify_amateur/features/gameStats/gamestats_screen.dart';
import 'package:sportify_amateur/features/gameStats/playerdetail_screen.dart';
import 'package:sportify_amateur/features/gameStats/playerstats_screen.dart';
import 'package:sportify_amateur/features/games/games_screen.dart';
import 'package:sportify_amateur/features/roles/roles_screen.dart';
import 'package:sportify_amateur/features/users/users_form_screen.dart';
import 'package:sportify_amateur/features/users/users_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = AuthStorageService();
  //print('Base URL: ${AppConfig.apiBaseUrl}');
  // Inicializar Dio con interceptores
  DioClient.initialize();
  // Limpia el token al iniciar la app (solo para pruebas)
  // await storageService.clearStoredToken();
  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: const MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Sportify Amateur',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => const UserLoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingWizard(),
        '/team-form': (context) => const TeamFormScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile/info': (context) => const ProfileInfoScreen(),
        '/profile/security': (context) => const SecurityScreen(),
        '/profile/admin': (context) => const AdminConfigScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/deleted-users': (context) => const DeletedUsersScreen(),
        '/admin/permissions': (context) => const PermissionsScreen(),
        '/sports/roster': (context) => const RosterManagementScreen(),
        '/teams': (context) => const TeamsManagementScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/secondary': (context) => const SecondaryHomeScreen(),
        '/roles': (context) => const RolesScreen(),
        '/users': (context) => const UsersScreen(),
        '/game-stats': (context) => const GameStatsScreen(),
        '/playerStats': (context) => PlayerStatsScreen(),
        '/comparePlayers': (context) => ComparePlayersScreen(),
        '/userDetail': (context) => UserFormScreen(),
        '/games': (context) => GamesScreen(),
        '/events': (context) => GamesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/player-detail') {
          final playerId =
              settings.arguments as int?; // Asegúrate de que sea un int
          if (playerId != null) {
            return MaterialPageRoute(
              builder: (context) => PlayerDetailScreen(playerId: playerId),
            );
          }
        }
        return null; // Si no coincide con ninguna ruta, retorna null
      },
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

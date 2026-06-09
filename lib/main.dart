import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/navigation/app_navigator.dart';
import 'package:sportify_amateur/core/services/push_registration_service.dart';
import 'package:sportify_amateur/firebase_background.dart';
import 'package:sportify_amateur/firebase_options.dart';
import 'package:sportify_amateur/core/common/themes_provider.dart';
import 'package:sportify_amateur/features/auth/login.dart';
import 'package:sportify_amateur/features/auth/user_login.dart';
import 'package:sportify_amateur/features/auth/register_screen.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/features/shell/app_shell_screen.dart';
import 'package:sportify_amateur/features/profile/profile_screen.dart';
import 'package:sportify_amateur/features/profile/profile_info_screen.dart';
import 'package:sportify_amateur/features/profile/security_screen.dart';
import 'package:sportify_amateur/features/profile/admin_config_screen.dart';
import 'package:sportify_amateur/features/admin/admin_users_screen.dart';
import 'package:sportify_amateur/features/admin/deleted_users_screen.dart';
import 'package:sportify_amateur/features/permissions/permissions_screen.dart';
import 'package:sportify_amateur/features/sports/sports_management_screen.dart';
import 'package:sportify_amateur/features/sports/sports_management_args.dart';
import 'package:sportify_amateur/features/sports/post_match_screen.dart';
import 'package:sportify_amateur/features/teams/teams_management_screen.dart';
import 'package:sportify_amateur/features/onboarding/onboarding_wizard.dart';
import 'package:sportify_amateur/features/onboarding/staff_team_setup_screen.dart';
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
import 'package:sportify_amateur/features/notifications/notification_screen.dart';
import 'package:sportify_amateur/features/finance/finance_hub_screen.dart';
import 'package:sportify_amateur/features/sports/my_events_screen.dart';
import 'package:sportify_amateur/features/sports/my_matches_screen.dart';
import 'package:sportify_amateur/features/teams/join_team_screen.dart';
import 'package:sportify_amateur/features/sports/team_admin_panel_screen.dart';
import 'package:sportify_amateur/features/finance/quota_overview_screen.dart';
import 'package:sportify_amateur/features/sports/attendance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  DioClient.initialize();
  // FCM: no debe bloquear el arranque si no hay sesión o el JWT expiró.
  try {
    await PushRegistrationService.instance.initialize();
  } catch (e) {
    debugPrint('FCM init: $e');
  }
  // Limpia el token al iniciar la app (solo para pruebas)
  // await storageService.clearStoredToken();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SeasonProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: AppNavigator.key,
      scaffoldMessengerKey: AppNavigator.messengerKey,
      title: 'Sportify Amateur',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => const UserLoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingWizard(),
        '/staff-team-setup': (context) => const StaffTeamSetupScreen(),
        '/team-form': (context) => const TeamFormScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile/info': (context) => const ProfileInfoScreen(),
        '/profile/security': (context) => const SecurityScreen(),
        '/profile/admin': (context) => const AdminConfigScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/deleted-users': (context) => const DeletedUsersScreen(),
        '/admin/permissions': (context) => const PermissionsScreen(),
        '/sports/roster': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is SportsManagementArgs) {
            return SportsManagementScreen(
              initialTabIndex: args.initialTabIndex,
              initialTeamId: args.initialTeamId,
            );
          }
          return const SportsManagementScreen();
        },
        '/teams': (context) => const TeamsManagementScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/my-events': (context) => const MyEventsScreen(),
        '/sports/my-matches': (context) => const MyMatchesScreen(),
        '/join-team': (context) => const JoinTeamScreen(),
        '/finances': (context) => const FinanceHubScreen(),
        '/sports/admin-panel': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int? teamId;
          if (args is Map) {
            final raw = args['teamId'];
            if (raw is int) teamId = raw;
            if (raw != null && teamId == null) teamId = int.tryParse('$raw');
          }
          return TeamAdminPanelScreen(initialTeamId: teamId);
        },
        '/finances/quota-overview': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int? teamId;
          if (args is Map) {
            final raw = args['teamId'];
            if (raw is int) teamId = raw;
            if (raw != null && teamId == null) teamId = int.tryParse('$raw');
          }
          if (teamId == null) {
            return const Scaffold(
              body: Center(child: Text('Falta teamId')),
            );
          }
          return QuotaOverviewScreen(teamId: teamId);
        },
        '/sports/attendance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int? teamId;
          if (args is Map) {
            final raw = args['teamId'];
            if (raw is int) teamId = raw;
            if (raw != null && teamId == null) teamId = int.tryParse('$raw');
          }
          if (teamId == null) {
            return const Scaffold(
              body: Center(child: Text('Falta teamId')),
            );
          }
          return AttendanceScreen(teamId: teamId);
        },
        '/dashboard': (context) => const AppShellScreen(),
        '/secondary': (context) => const SecondaryHomeScreen(),
        '/roles': (context) => const RolesScreen(),
        '/users': (context) => const UsersScreen(),
        '/game-stats': (context) => const GameStatsScreen(),
        '/playerStats': (context) => PlayerStatsScreen(),
        '/comparePlayers': (context) => ComparePlayersScreen(),
        '/userDetail': (context) => UserFormScreen(),
        '/games': (context) => GamesScreen(),
        '/events': (context) => GamesScreen(),
        '/sports/post-match': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          int? eventId;
          if (args is Map) {
            final raw = args['eventId'];
            if (raw is int) eventId = raw;
            if (raw != null && eventId == null) {
              eventId = int.tryParse('$raw');
            }
          }
          if (eventId == null) {
            return const Scaffold(
              body: Center(child: Text('Falta eventId para gestionar partido')),
            );
          }
          return PostMatchScreen(eventId: eventId);
        },
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

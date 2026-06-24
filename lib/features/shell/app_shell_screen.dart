import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/common/team_branding_provider.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/dashboard/home_screen.dart';
import 'package:sportify_amateur/features/finance/finance_hub_screen.dart';
import 'package:sportify_amateur/features/sports/my_events_screen.dart';
import 'package:sportify_amateur/features/sports/sports_management_screen.dart';
import 'package:sportify_amateur/features/sports/team_admin_panel_screen.dart';
import 'package:sportify_amateur/features/sports/my_matches_screen.dart';
import 'package:sportify_amateur/features/finance/quota_overview_screen.dart';
import 'package:sportify_amateur/features/notifications/notification_screen.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/features/teams/join_team_screen.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';
import 'package:sportify_amateur/features/reports/reports_hub_screen.dart';
import 'package:sportify_amateur/features/sponsors/sponsors_screen.dart';
import 'package:sportify_amateur/features/audit/audit_log_screen.dart';
import 'package:sportify_amateur/features/onboarding/team_onboarding_screen.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:sportify_amateur/widgets/team_branded_app_overlay.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 2;
  String? _role;
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.startBackgroundSync();
    _loadRole();
    context.read<SeasonProvider>().load();
    context.read<TeamBrandingProvider>().load();
    _guardStaffTeamSetup();
  }

  Future<void> _guardStaffTeamSetup() async {
    final authStatus = await AuthService().checkAuthStatus();
    if (!mounted) return;
    if (authStatus['needsTeamSetup'] == true) {
      Navigator.pushReplacementNamed(context, '/staff-team-setup');
    }
  }

  Future<void> _loadRole() async {
    final role = await AuthService().syncStoredRoleFromServer();
    if (mounted) setState(() => _role = role);
  }

  bool get _isStaff {
    final r = _role;
    return r == 'super_admin' ||
        r == 'manager' ||
        r == 'admin' ||
        r == 'team_captain' ||
        r == 'dt';
  }

  bool get _isManager {
    final r = _role;
    return r == 'super_admin' || r == 'manager' || r == 'admin';
  }

  bool get _canEditTeam => UserCapabilities.canManageTeamSettings(_role);

  List<Widget> _moreMenuTiles(BuildContext ctx) {
    return [
      if (_isStaff)
        ListTile(
          leading: _menuIcon(Icons.dashboard_customize, Colors.teal),
          title: const Text('Panel del equipo'),
          subtitle: const Text('Morosos, confirmaciones, caja del mes'),
          onTap: () {
            Navigator.pop(ctx);
            _openAdminPanel();
          },
        ),
      if (_canEditTeam)
        ListTile(
          leading: _menuIcon(Icons.edit_outlined, Colors.deepPurple),
          title: const Text('Editar equipo'),
          subtitle: const Text('Nombre, logo, colores y categorías'),
          onTap: () {
            Navigator.pop(ctx);
            _openEditTeam();
          },
        ),
      ListTile(
        leading: _menuIcon(Icons.how_to_vote, Colors.green),
        title: const Text('Mis partidos'),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyMatchesScreen()),
          );
        },
      ),
      ListTile(
        leading: _menuIcon(Icons.groups, Colors.blue),
        title: const Text('Cuotas del plantel'),
        onTap: () {
          Navigator.pop(ctx);
          _openQuotaOverview();
        },
      ),
      ListTile(
        leading: _menuIcon(Icons.assessment, Colors.indigo),
        title: const Text('Informes'),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsHubScreen()),
          );
        },
      ),
      ListTile(
        leading: _menuIcon(Icons.business, Colors.deepOrange),
        title: const Text('Patrocinadores'),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SponsorsScreen()),
          );
        },
      ),
      if (_isStaff)
        ListTile(
          leading: _menuIcon(Icons.history, Colors.blueGrey),
          title: const Text('Auditoría'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuditLogScreen()),
            );
          },
        ),
      if (_isStaff)
        ListTile(
          leading: _menuIcon(Icons.person_add_alt_1, Colors.teal),
          title: const Text('Alta en buena fe (invitación)'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeamOnboardingScreen(),
              ),
            );
          },
        ),
      ListTile(
        leading: _menuIcon(Icons.vpn_key, Colors.amber.shade800),
        title: const Text('Unirme con código'),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinTeamScreen()),
          );
        },
      ),
      if (_isManager)
        ListTile(
          leading: _menuIcon(Icons.groups_3, Colors.blue),
          title: const Text('Gestión de equipos'),
          onTap: () {
            Navigator.pop(ctx);
            Navigator.pushNamed(context, '/teams');
          },
        ),
      ListTile(
        leading: StreamBuilder<int>(
          stream: _notificationService.unreadCountStream,
          initialData: 0,
          builder: (_, snap) {
            final c = snap.data ?? 0;
            return Badge(
              isLabelVisible: c > 0,
              label: Text(c > 99 ? '99+' : '$c'),
              child: _menuIcon(Icons.notifications, Colors.orange),
            );
          },
        ),
        title: const Text('Notificaciones'),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          ).then((_) => _notificationService.refreshUnreadCount());
        },
      ),
      ListTile(
        leading: _menuIcon(Icons.account_circle, Colors.blueGrey),
        title: const Text('Perfil'),
        onTap: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, '/profile');
        },
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _menuIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Más opciones',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ..._moreMenuTiles(ctx),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAdminPanel() async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await TeamService().getMyTeams());
      if (teams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tenés equipos asignados')),
          );
        }
        return;
      }
      int? teamId = teams.first.teamId;
      if (teams.length > 1) {
        final picked = await showModalBottomSheet<MyTeamOption>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: teams
                  .map(
                    (t) => ListTile(
                      title: Text(t.listLabel(teams)),
                      onTap: () => Navigator.pop(ctx, t),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        if (picked == null) return;
        teamId = picked.teamId;
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamAdminPanelScreen(initialTeamId: teamId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openEditTeam() async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await TeamService().getMyTeams());
      if (teams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No tenés equipos asignados')),
          );
        }
        return;
      }
      int teamId = teams.first.teamId;
      if (teams.length > 1) {
        final picked = await showModalBottomSheet<MyTeamOption>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: teams
                  .map(
                    (t) => ListTile(
                      title: Text(t.listLabel(teams)),
                      onTap: () => Navigator.pop(ctx, t),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        if (picked == null) return;
        teamId = picked.teamId;
      }
      final team = await TeamService().getTeamById(teamId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeamFormScreen(team: team)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openQuotaOverview() async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await TeamService().getMyTeams());
      if (teams.isEmpty) return;
      int teamId = teams.first.teamId;
      if (teams.length > 1) {
        final picked = await showModalBottomSheet<MyTeamOption>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: teams
                  .map(
                    (t) => ListTile(
                      title: Text(t.listLabel(teams)),
                      onTap: () => Navigator.pop(ctx, t),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        if (picked == null) return;
        teamId = picked.teamId;
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuotaOverviewScreen(teamId: teamId),
        ),
      );
    } catch (_) {}
  }

  void _selectTab(int index) {
    if (index == 4) {
      _showMoreMenu();
      return;
    }
    setState(() => _index = index);
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final selected = _index == index;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectTab(index),
          borderRadius: BorderRadius.circular(12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: selected
                        ? primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _homeDockButton({
    required ThemeData theme,
    required Color primary,
  }) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      color: primary,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _index = 2),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            Icons.home_rounded,
            size: 26,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppShellScope(
      selectTab: _selectTab,
      activeTabIndex: _index,
      child: Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: TeamBrandedAppOverlay(
        child: IndexedStack(
          index: _index.clamp(0, 3),
          children: const [
            SportsManagementScreen(),
            FinanceHubScreen(),
            HomeScreen(),
            MyEventsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          const barHeight = 62.0;
          const buttonSize = 56.0;
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          // Centro del botón al borde superior de la barra (mitad arriba, mitad adentro).
          final buttonBottom = bottomInset + barHeight - buttonSize / 2;

          return SizedBox(
            height: buttonBottom + buttonSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Material(
                    elevation: 16,
                    shadowColor: Colors.black38,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.95 : 1,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: BottomAppBar(
                        height: barHeight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        elevation: 0,
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _navItem(
                              index: 0,
                              icon: Icons.sports_soccer_outlined,
                              selectedIcon: Icons.sports_soccer_rounded,
                              label: 'Deportiva',
                            ),
                            _navItem(
                              index: 1,
                              icon: Icons.payments_outlined,
                              selectedIcon: Icons.payments_rounded,
                              label: 'Finanzas',
                            ),
                            const SizedBox(width: 64),
                            _navItem(
                              index: 3,
                              icon: Icons.event_outlined,
                              selectedIcon: Icons.event_rounded,
                              label: 'Eventos',
                            ),
                            _navItem(
                              index: 4,
                              icon: Icons.apps_outlined,
                              selectedIcon: Icons.apps_rounded,
                              label: 'Más',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: buttonBottom,
                  child: Center(
                    child: _homeDockButton(
                      theme: theme,
                      primary: primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }
}

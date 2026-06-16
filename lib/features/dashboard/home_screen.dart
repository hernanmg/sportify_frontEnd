import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/themes_provider.dart';
import 'package:sportify_amateur/core/common/team_branding_provider.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/role_service.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/features/dashboard/team_membership_banner.dart';
import 'package:sportify_amateur/features/help/home_help_search_bar.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:sportify_amateur/widgets/smooth_header_gradient.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _role;
  String? _userName;
  bool _helpSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeamBrandingProvider>().load();
      }
    });
  }

  Future<void> _load() async {
    final auth = AuthStorageService();
    final syncedRole = await AuthService().syncStoredRoleFromServer();
    final role = syncedRole ?? await auth.getRole();
    final name = await auth.getUserName();
    if (mounted) {
      setState(() {
        _role = role;
        _userName = name;
      });
    }
  }

  bool get _isPlatformAdmin => UserCapabilities.isPlatformAdmin(_role);

  bool get _isTeamStaff => UserCapabilities.isStaff(_role);

  bool get _isPlayer =>
      _role != null && UserCapabilities.isPlayer(_role) && !_isTeamStaff;

  void _openHelp(String query) {
    Navigator.pushNamed(
      context,
      '/help',
      arguments: {'query': query},
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _userName != null && _userName!.isNotEmpty ? 148 : 128,
            pinned: true,
            stretch: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            actions: [
              HomeHelpSearchBar(
                expanded: _helpSearchOpen,
                onExpandedChanged: (v) => setState(() => _helpSearchOpen = v),
                onSearch: _openHelp,
              ),
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              Switch(
                value: isDark,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.45),
                inactiveThumbColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                onChanged: themeProvider.toggleTheme,
              ),
            ],
            flexibleSpace: Stack(
              fit: StackFit.expand,
              children: [
                SmoothHeaderGradient.primary(primary),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.38),
                        ],
                      ),
                    ),
                  ),
                ),
                FlexibleSpaceBar(
                  stretchModes: const [],
                  centerTitle: false,
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    bottom: 14,
                  ),
                  title: _userName != null && _userName!.isNotEmpty
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, $_userName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            if (_role != null && _role!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  RoleService.getRoleDisplayName(_role!),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          'Sportify Amateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 8,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                  background: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TeamMembershipBanner(),
                  const SizedBox(height: 8),
                  Text(
                    'Accesos rápidos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _QuickTile(
                    icon: Icons.sports_soccer,
                    title: 'Gestión Deportiva',
                    subtitle: 'Plantel, eventos, convocatorias',
                    color: Colors.green,
                    onTap: () => _switchTab(context, 0),
                  ),
                  _QuickTile(
                    icon: Icons.payments,
                    title: 'Finanzas',
                    subtitle: 'Mi cuenta, movimientos, cuotas',
                    color: Colors.teal,
                    onTap: () => _switchTab(context, 1),
                  ),
                  _QuickTile(
                    icon: Icons.event_available,
                    title: 'Mis eventos',
                    subtitle: 'Sociales y confirmaciones',
                    color: Colors.deepPurple,
                    onTap: () => _switchTab(context, 3),
                  ),
                  _QuickTile(
                    icon: Icons.help_outline,
                    title: 'Centro de ayuda',
                    subtitle: 'Guías paso a paso de cada función',
                    color: Colors.orange,
                    onTap: () => _openHelp(''),
                  ),
                  if (_isPlayer) ...[
                    _QuickTile(
                      icon: Icons.person,
                      title: 'Mi perfil',
                      subtitle: 'Editá tus datos y de qué hincha sos',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/profile/info'),
                    ),
                    _QuickTile(
                      icon: Icons.vpn_key,
                      title: 'Unirme con código',
                      subtitle: 'Sumate al plantel de tu equipo',
                      color: Colors.amber.shade800,
                      onTap: () => Navigator.pushNamed(context, '/join-team'),
                    ),
                    _QuickTile(
                      icon: Icons.how_to_vote,
                      title: 'Mis partidos',
                      subtitle: 'Confirmá convocatorias y asistencia',
                      color: Colors.green,
                      onTap: () =>
                          Navigator.pushNamed(context, '/sports/my-matches'),
                    ),
                  ],
                  if (_isPlatformAdmin)
                    _QuickTile(
                      icon: Icons.groups_3,
                      title: 'Gestión de equipos',
                      subtitle: 'Clubes, deportes, categorías, duplicados',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/teams'),
                    ),
                  if (_isTeamStaff)
                    _QuickTile(
                      icon: Icons.dashboard_customize,
                      title: 'Panel del equipo',
                      subtitle: 'Morosos, caja del mes, asistencias',
                      color: Colors.teal,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/sports/admin-panel',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchTab(BuildContext context, int index) {
    AppShellScope.maybeOf(context)?.selectTab(index);
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

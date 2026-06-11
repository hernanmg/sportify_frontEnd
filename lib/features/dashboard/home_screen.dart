import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/themes_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/features/dashboard/team_membership_banner.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthStorageService();
    final role = await auth.getRole();
    final name = await auth.getUserName();
    if (mounted) {
      setState(() {
        _role = role;
        _userName = name;
      });
    }
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
            expandedHeight: 128,
            pinned: true,
            stretch: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            actions: [
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
                  title: Text(
                    _userName != null && _userName!.isNotEmpty
                        ? 'Hola, $_userName'
                        : 'Sportify Amateur',
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
                  if (_role == 'super_admin' ||
                      _role == 'manager' ||
                      _role == 'admin')
                    _QuickTile(
                      icon: Icons.groups_3,
                      title: 'Gestión de equipos',
                      subtitle: 'Clubes, deportes, categorías, duplicados',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/teams'),
                    ),
                  if (_role == 'super_admin' ||
                      _role == 'manager' ||
                      _role == 'admin')
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

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

/// Muestra los equipos del usuario en el dashboard.
class TeamMembershipBanner extends StatefulWidget {
  const TeamMembershipBanner({super.key});

  @override
  State<TeamMembershipBanner> createState() => _TeamMembershipBannerState();
}

class _TeamMembershipBannerState extends State<TeamMembershipBanner> {
  final _teamService = TeamService();
  List<MyTeamOption> _teams = [];
  bool _loading = true;
  bool _isPlatformAdmin = false;
  int? _lastHomeVisitTab;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppShellScope.maybeOf(context);
    final tab = scope?.activeTabIndex;
    if (tab == AppShellScope.homeTabIndex && _lastHomeVisitTab != tab) {
      _load();
    }
    _lastHomeVisitTab = tab;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final role = await AuthStorageService().getRole();
      final isPlatformAdmin =
          role == 'super_admin' || role == 'manager' || role == 'admin';

      var teams = await _teamService.getMyTeams();
      if (teams.isEmpty && isPlatformAdmin) {
        final all = await _teamService.getAllTeams();
        teams = all
            .map(
              (t) => MyTeamOption(
                teamId: t.id,
                name: t.name,
                categories: t.categoryNames,
                categoryIds: t.categoryIds,
                isTeamAdmin: true,
                team: t,
              ),
            )
            .toList();
      }

      if (mounted) {
        setState(() {
          _isPlatformAdmin = isPlatformAdmin;
          _teams = MyTeamOption.dedupeByTeamId(teams);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (_teams.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, color: Colors.green),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mis equipos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _load,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._teams.map((t) {
              final label = t.listLabel(_teams);
              final admin = t.isTeamAdmin ? ' (encargado)' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label$admin',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? theme.colorScheme.secondaryContainer
        : Colors.amber.shade50;
    final fg = isDark
        ? theme.colorScheme.onSecondaryContainer
        : Colors.amber.shade900;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sin equipo asignado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isPlatformAdmin
                  ? 'Creá tu club desde Gestión de equipos o el botón de abajo. '
                      'Al crearlo quedás como encargado automáticamente.'
                  : 'Pedile el código a tu capitán o director técnico para unirte al plantel.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg.withValues(alpha: 0.92),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_isPlatformAdmin) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/team-form');
                      if (mounted) _load();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Crear equipo'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/teams');
                      if (mounted) _load();
                    },
                    child: const Text('Gestión de equipos'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/join-team');
                      if (mounted) _load();
                    },
                    child: const Text('Unirme con código'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

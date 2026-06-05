import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final role = await AuthStorageService().getRole();
      final teams = await _teamService.getMyTeams();
      if (mounted) {
        setState(() {
          _isPlatformAdmin =
              role == 'super_admin' || role == 'manager' || role == 'admin';
          _teams = teams;
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
            const Row(
              children: [
                Icon(Icons.groups, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Mis equipos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._teams.map((t) {
              final cats = t.categories.isEmpty
                  ? ''
                  : ' · ${t.categories.join(', ')}';
              final admin = t.isTeamAdmin ? ' (encargado)' : '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.sports_soccer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t.name}$cats$admin',
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
                  ? 'Si ya creaste el equipo en Gestión de equipos, abrí la pestaña Equipos → menú ⋮ del club → Asignarme como encargado.'
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
                    onPressed: () =>
                        Navigator.pushNamed(context, '/team-form'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Crear equipo'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/teams'),
                    child: const Text('Gestión de equipos'),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/join-team'),
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

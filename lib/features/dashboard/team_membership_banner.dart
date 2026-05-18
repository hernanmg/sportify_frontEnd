import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final teams = await _teamService.getMyTeams();
      if (mounted) {
        setState(() {
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
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.amber.shade50,
        child: ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.amber),
          title: const Text('Sin equipo asignado'),
          subtitle: const Text(
            'Unite con un código o creá tu equipo desde el menú ⋮ en Gestión Deportiva',
          ),
          trailing: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/join-team'),
            child: const Text('Unirme'),
          ),
        ),
      );
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
}

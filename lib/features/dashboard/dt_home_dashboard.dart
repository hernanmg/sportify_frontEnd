import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/team_admin_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:sportify_amateur/features/sports/convocation_form_screen.dart';
import 'package:sportify_amateur/features/sports/post_match_screen.dart';
import 'package:sportify_amateur/features/sports/sports_management_args.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

/// Resumen operativo para DT / cuerpo técnico en la pantalla de Inicio.
class DtHomeDashboard extends StatefulWidget {
  const DtHomeDashboard({super.key});

  @override
  State<DtHomeDashboard> createState() => _DtHomeDashboardState();
}

class _DtHomeDashboardState extends State<DtHomeDashboard> {
  final _adminService = TeamAdminService();
  final _teamService = TeamService();

  TeamAdminPanel? _panel;
  MyTeamOption? _team;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final teams = MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (teams.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _panel = null;
          _team = null;
        });
        return;
      }
      final team = teams.first;
      final panel = await _adminService.getAdminPanel(team.teamId);
      if (!mounted) return;
      setState(() {
        _team = team;
        _panel = panel;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TeamAdminService.errorMessage(e);
        _loading = false;
      });
    }
  }

  void _openSports({int tabIndex = 0}) {
    AppShellScope.maybeOf(context)?.selectTab(0);
    Navigator.pushNamed(
      context,
      '/sports/roster',
      arguments: SportsManagementArgs(initialTabIndex: tabIndex),
    );
  }

  void _openAdminPanel() {
    final teamId = _team?.teamId;
    if (teamId == null) return;
    Navigator.pushNamed(
      context,
      '/sports/admin-panel',
      arguments: {'teamId': teamId},
    );
  }

  void _openLineup(int eventId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostMatchScreen(eventId: eventId, eventTitle: title),
      ),
    );
  }

  Future<void> _editTeam() async {
    final teamId = _team?.teamId;
    if (teamId == null) return;
    try {
      final team = await _teamService.getTeamById(teamId);
      if (!mounted) return;
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamFormScreen(team: team),
        ),
      );
      if (updated != null) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TeamService.errorMessage(e))),
      );
    }
  }

  Future<void> _newConvocation() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConvocationFormScreen()),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(_error!),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ),
      );
    }

    final panel = _panel;
    if (panel == null) return const SizedBox.shrink();

    final dateFmt = DateFormat('EEE d/M HH:mm', 'es');
    final next = panel.nextConvocation;
    final pendingEvents = panel.pendingConfirmations;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard_customize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Panel DT — ${_team?.name ?? 'Equipo'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.sports_soccer,
                title: next.title,
                subtitle:
                    'vs ${next.opponentName ?? 'rival'} · ${dateFmt.format(next.eventDate)}',
                trailing:
                    '${next.confirmed}/${next.convoked} confirmados · ${next.pending} pend.',
                onTap: () => _openSports(tabIndex: 2),
              ),
            ],
            if (pendingEvents.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sin confirmar',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ...pendingEvents.take(2).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _InfoTile(
                        icon: Icons.hourglass_top,
                        title: e.title,
                        subtitle: dateFmt.format(e.eventDate),
                        trailing: '${e.pendingCount} pendiente(s)',
                        onTap: () => _openSports(tabIndex: 2),
                      ),
                    ),
                  ),
            ],
            if (panel.debtors.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoTile(
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange.shade800,
                title: 'Cuotas pendientes en plantel',
                subtitle:
                    '${panel.debtors.length} con cuota pendiente — pueden quedar fuera de partido oficial',
                trailing: formatMoney(panel.debtors.first.balance),
                onTap: _openAdminPanel,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva convocatoria'),
                  onPressed: _newConvocation,
                ),
                if (next != null)
                  ActionChip(
                    avatar: const Icon(Icons.grid_view, size: 18),
                    label: const Text('Alineación'),
                    onPressed: () => _openLineup(next.id, next.title),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar equipo'),
                  onPressed: _editTeam,
                ),
                ActionChip(
                  avatar: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Plantel'),
                  onPressed: () => _openSports(tabIndex: 0),
                ),
                ActionChip(
                  avatar: const Icon(Icons.fact_check, size: 18),
                  label: const Text('Panel equipo'),
                  onPressed: _openAdminPanel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatMoney(double amount) {
  return '\$${amount.toStringAsFixed(0)}';
}

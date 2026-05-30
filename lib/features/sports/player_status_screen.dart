import 'package:flutter/material.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/player_status_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/features/sports/player_convocation_stats_screen.dart';
import 'package:sportify_amateur/models/player_eligibility.dart';

class PlayerStatusScreen extends StatefulWidget {
  final int? initialTeamId;

  const PlayerStatusScreen({super.key, this.initialTeamId});

  @override
  State<PlayerStatusScreen> createState() => PlayerStatusScreenState();
}

class PlayerStatusScreenState extends State<PlayerStatusScreen> {
  static const _prefViewKey = 'player_status_view_grid';

  final _statusService = PlayerStatusService();
  final _teamService = TeamService();

  List<MyTeamOption> _teams = [];
  MyTeamOption? _selectedTeam;
  List<PlayerEligibility> _players = [];
  bool _loading = true;
  bool _gridView = false;
  bool _defaultViewApplied = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_prefViewKey)) {
      _gridView = prefs.getBool(_prefViewKey) ?? false;
    }
    await _loadTeams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultViewApplied) return;
    _defaultViewApplied = true;
    SharedPreferences.getInstance().then((prefs) {
      if (!prefs.containsKey(_prefViewKey) && mounted) {
        setState(() => _gridView = MediaQuery.sizeOf(context).width >= 600);
      }
    });
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      var teams = await _teamService.getMyTeams();
      if (teams.isEmpty) {
        final all = await _teamService.getAllTeams();
        teams = all
            .map(
              (t) => MyTeamOption(
                teamId: t.id,
                name: t.name,
                categories: t.categoryNames,
                categoryIds: t.categoryIds,
                team: t,
              ),
            )
            .toList();
      }
      teams = MyTeamOption.dedupeByTeamId(teams);
      final previousId = _selectedTeam?.teamId;
      final preferredId = widget.initialTeamId ?? previousId;
      setState(() {
        _teams = teams;
        _selectedTeam = (preferredId != null
                ? MyTeamOption.findInList(teams, preferredId)
                : null) ??
            (teams.isNotEmpty ? teams.first : null);
      });
      await reload();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> reload() async {
    final team = _selectedTeam;
    if (team == null) {
      setState(() {
        _players = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final list = await _statusService.getTeamEligibility(team.teamId);
      setState(() {
        _players = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleView(bool grid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefViewKey, grid);
    setState(() => _gridView = grid);
  }

  void _openDetail(PlayerEligibility player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PlayerStatusSheet(
        player: player,
        teamId: _selectedTeam!.teamId,
        onChanged: () {
          Navigator.pop(ctx);
          reload();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: _teams.isEmpty
                    ? const Text('Sin equipos')
                    : DropdownButtonFormField<MyTeamOption>(
                        value: _selectedTeam != null &&
                                _teams.any(
                                  (t) => t.teamId == _selectedTeam!.teamId,
                                )
                            ? _selectedTeam
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Equipo',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _teams
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name),
                              ),
                            )
                            .toList(),
                        onChanged: (t) async {
                          setState(() => _selectedTeam = t);
                          await reload();
                        },
                      ),
              ),
              IconButton(
                tooltip: 'Lista',
                onPressed: () => _toggleView(false),
                icon: Icon(
                  Icons.view_list,
                  color: !_gridView ? Colors.green : null,
                ),
              ),
              IconButton(
                tooltip: 'Grilla',
                onPressed: () => _toggleView(true),
                icon: Icon(
                  Icons.grid_view,
                  color: _gridView ? Colors.green : null,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _players.isEmpty
                  ? const Center(child: Text('No hay jugadores en el plantel'))
                  : _gridView
                      ? _buildGrid()
                      : _buildList(),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _players.length,
      itemBuilder: (context, i) {
        final p = _players[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: PlayerAvatar(
              avatarUrl: p.avatarUrl,
              displayName: p.playerName,
              radius: 22,
              backgroundColor: p.color.materialColor.withValues(alpha: 0.2),
              badgeText: '${p.jerseyNumber ?? '?'}',
            ),
            title: Text(p.playerName),
            subtitle: Text('${p.statusEmoji} ${p.reason}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openDetail(p),
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    final crossCount = MediaQuery.sizeOf(context).width >= 900
        ? 6
        : MediaQuery.sizeOf(context).width >= 600
            ? 4
            : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _players.length,
      itemBuilder: (context, i) {
        final p = _players[i];
        return InkWell(
          onTap: () => _openDetail(p),
          child: _JerseyTile(player: p),
        );
      },
    );
  }
}

class _JerseyTile extends StatelessWidget {
  final PlayerEligibility player;

  const _JerseyTile({required this.player});

  @override
  Widget build(BuildContext context) {
    final color = player.color.materialColor;
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${player.jerseyNumber ?? '?'}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            player.playerName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            player.statusEmoji,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _PlayerStatusSheet extends StatefulWidget {
  final PlayerEligibility player;
  final int teamId;
  final VoidCallback onChanged;

  const _PlayerStatusSheet({
    required this.player,
    required this.teamId,
    required this.onChanged,
  });

  @override
  State<_PlayerStatusSheet> createState() => _PlayerStatusSheetState();
}

class _PlayerStatusSheetState extends State<_PlayerStatusSheet> {
  final _service = PlayerStatusService();
  final _descController = TextEditingController();
  final _daysController = TextEditingController(text: '7');
  String _impType = 'injury';

  @override
  void dispose() {
    _descController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#${p.jerseyNumber ?? '–'} ${p.playerName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('${p.statusEmoji} ${p.statusLabel}'),
            Text(p.reason),
            if (p.daysRemaining != null)
              Text('Días restantes: ${p.daysRemaining}'),
            if (p.feeOverride != null)
              Text(
                'Override de cuota activo',
                style: TextStyle(color: Colors.blue.shade700),
              ),
            const Divider(height: 24),
            if (p.status == EligibilityStatus.feeUnpaid) ...[
              FilledButton(
                onPressed: () async {
                  await _service.setFeeOverride(
                    widget.teamId,
                    p.userId,
                    reason: 'Habilitación manual DT',
                  );
                  widget.onChanged();
                },
                child: const Text('Habilitar cuota (override)'),
              ),
            ],
            if (p.feeOverride != null)
              OutlinedButton(
                onPressed: () async {
                  await _service.clearFeeOverride(widget.teamId, p.userId);
                  widget.onChanged();
                },
                child: const Text('Quitar override de cuota'),
              ),
            const SizedBox(height: 12),
            const Text(
              'Registrar impedimento',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            DropdownButtonFormField<String>(
              value: _impType,
              items: const [
                DropdownMenuItem(value: 'injury', child: Text('Lesión')),
                DropdownMenuItem(
                  value: 'suspension',
                  child: Text('Suspensión'),
                ),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (v) => setState(() => _impType = v ?? 'injury'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duración (días)',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final days = int.tryParse(_daysController.text);
                try {
                  await _service.createImpediment(
                    widget.teamId,
                    userId: p.userId,
                    impedimentType: _impType,
                    startDate:
                        DateTime.now().toIso8601String().substring(0, 10),
                    durationDays: days,
                    description: _descController.text.trim().isEmpty
                        ? null
                        : _descController.text.trim(),
                  );
                  if (!context.mounted) return;
                  final myId =
                      int.tryParse(await AuthStorageService().getUserId() ?? '');
                  final msg = myId != null && myId == p.userId
                      ? 'Impedimento guardado. Se notificó al DT/admin del equipo.'
                      : 'Impedimento guardado. Aviso enviado a ${p.playerName} y al cuerpo técnico.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                  widget.onChanged();
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Guardar impedimento'),
            ),
            if (p.activeImpedimentId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  await _service.clearImpediment(
                    widget.teamId,
                    p.activeImpedimentId!,
                  );
                  widget.onChanged();
                },
                child: const Text('Dar de alta / quitar impedimento'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerConvocationStatsScreen(
                      teamId: widget.teamId,
                      userId: p.userId,
                      playerName: p.playerName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('Historial de convocatorias'),
            ),
          ],
        ),
      ),
    );
  }
}

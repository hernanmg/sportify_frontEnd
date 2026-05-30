import 'package:flutter/material.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';
import 'package:sportify_amateur/core/services/post_match_service.dart';
import 'package:sportify_amateur/models/post_match.dart';

class PostMatchAttendanceTab extends StatefulWidget {
  final PostMatchData data;
  final PostMatchService service;
  final VoidCallback onUpdated;
  final void Function(String msg, {bool error}) onMessage;

  const PostMatchAttendanceTab({
    super.key,
    required this.data,
    required this.service,
    required this.onUpdated,
    required this.onMessage,
  });

  @override
  State<PostMatchAttendanceTab> createState() =>
      _PostMatchAttendanceTabState();
}

class _PostMatchAttendanceTabState extends State<PostMatchAttendanceTab> {
  late Map<int, bool?> _attended;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _attended = {
      for (final p in widget.data.lineup) p.userId: p.attended,
    };
  }

  @override
  void didUpdateWidget(covariant PostMatchAttendanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.eventId != widget.data.eventId) {
      _attended = {
        for (final p in widget.data.lineup) p.userId: p.attended,
      };
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final items = _attended.entries
          .where((e) => e.value != null)
          .map((e) => {'userId': e.key, 'attended': e.value})
          .toList();
      await widget.service.updateAttendance(widget.data.eventId, items);
      widget.onMessage('Asistencia guardada');
      widget.onUpdated();
    } catch (e) {
      widget.onMessage(PostMatchService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.lineup.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay jugadores convocados. Armá el plantel en la convocatoria.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        if (widget.data.canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Marcá quién asistió al partido.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: widget.data.lineup.length,
            itemBuilder: (_, i) {
              final p = widget.data.lineup[i];
              final att = _attended[p.userId];
              return Card(
                child: ListTile(
                  leading: PlayerAvatar(
                    avatarUrl: p.avatarUrl,
                    displayName: p.userName,
                    radius: 18,
                    badgeText: p.jerseyNumber?.toString(),
                  ),
                  title: Text(p.userName),
                  subtitle: Text(p.isStarter ? 'Titular' : 'Suplente'),
                  trailing: widget.data.canManage
                      ? SegmentedButton<bool?>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text('No'),
                              icon: Icon(Icons.close, size: 16),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Sí'),
                              icon: Icon(Icons.check, size: 16),
                            ),
                          ],
                          selected: {att},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (s) {
                            setState(() => _attended[p.userId] = s.firstOrNull);
                          },
                        )
                      : Text(_attendanceLabel(att)),
                ),
              );
            },
          ),
        ),
        if (widget.data.canManage)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar asistencia'),
              ),
            ),
          ),
      ],
    );
  }

  String _attendanceLabel(bool? att) {
    if (att == true) return 'Presente';
    if (att == false) return 'Ausente';
    return 'Sin registrar';
  }
}

class PostMatchLineupTab extends StatefulWidget {
  final PostMatchData data;
  final PostMatchService service;
  final VoidCallback onUpdated;
  final void Function(String msg, {bool error}) onMessage;

  const PostMatchLineupTab({
    super.key,
    required this.data,
    required this.service,
    required this.onUpdated,
    required this.onMessage,
  });

  @override
  State<PostMatchLineupTab> createState() => _PostMatchLineupTabState();
}

class _LineupEdit {
  String? position;
  String role;
  bool isStarter;

  _LineupEdit({
    required this.position,
    required this.role,
    required this.isStarter,
  });
}

class _PostMatchLineupTabState extends State<PostMatchLineupTab> {
  late Map<int, _LineupEdit> _edits;
  late Map<int, TextEditingController> _positionControllers;
  bool _saving = false;

  static const _roles = [
    ('player', 'Jugador'),
    ('substitute', 'Suplente'),
    ('coach', 'DT'),
    ('staff', 'Staff'),
  ];

  @override
  void initState() {
    super.initState();
    _positionControllers = {};
    _loadFromData();
  }

  void _loadFromData() {
    for (final c in _positionControllers.values) {
      c.dispose();
    }
    _edits = {
      for (final p in widget.data.lineup)
        p.userId: _LineupEdit(
          position: p.playingPosition,
          role: p.role,
          isStarter: p.isStarter,
        ),
    };
    _positionControllers = {
      for (final p in widget.data.lineup)
        p.userId: TextEditingController(text: p.playingPosition ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _positionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final items = _edits.entries
          .map(
            (e) => {
              'userId': e.key,
              'playingPosition':
                  _positionControllers[e.key]?.text.trim().isEmpty ?? true
                      ? null
                      : _positionControllers[e.key]!.text.trim(),
              'role': e.value.role,
              'isStarter': e.value.isStarter,
            },
          )
          .toList();
      await widget.service.updateLineup(
        widget.data.eventId,
        items: items,
      );
      widget.onMessage('Alineación guardada');
      widget.onUpdated();
    } catch (e) {
      widget.onMessage(PostMatchService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.lineup.isEmpty) {
      return const Center(child: Text('Sin plantel convocado'));
    }

    final starters = widget.data.lineup
        .where((p) => _edits[p.userId]?.isStarter ?? p.isStarter)
        .toList();
    final subs = widget.data.lineup
        .where((p) => !(_edits[p.userId]?.isStarter ?? p.isStarter))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (!widget.data.canManage) ...[
                _SectionTitle('Titulares (${starters.length})'),
                ...starters.map((p) => _LineupReadCard(row: p)),
                const SizedBox(height: 12),
                _SectionTitle('Suplentes (${subs.length})'),
                ...subs.map((p) => _LineupReadCard(row: p)),
              ] else ...[
                ...widget.data.lineup.map((p) {
                  final edit = _edits[p.userId]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.jerseyNumber != null
                                ? '${p.userName} #${p.jerseyNumber}'
                                : p.userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Posición',
                              hintText: 'Ej: Delantero, Arquero',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            controller: _positionControllers[p.userId],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: edit.role,
                            decoration: const InputDecoration(
                              labelText: 'Rol',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r.$1,
                                    child: Text(r.$2),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => edit.role = v);
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Titular'),
                            value: edit.isStarter,
                            onChanged: (v) =>
                                setState(() => edit.isStarter = v),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        if (widget.data.canManage)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Guardar alineación'),
              ),
            ),
          ),
      ],
    );
  }
}

class _LineupReadCard extends StatelessWidget {
  final PostMatchLineupRow row;

  const _LineupReadCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            row.jerseyNumber?.toString() ?? row.userName[0].toUpperCase(),
          ),
        ),
        title: Text(row.userName),
        subtitle: Text(
          [
            if (row.playingPosition != null) row.playingPosition!,
            row.roleLabel,
          ].join(' · '),
        ),
        trailing: row.isStarter
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class PostMatchStatsTab extends StatefulWidget {
  final PostMatchData data;
  final PostMatchService service;
  final VoidCallback onUpdated;
  final void Function(String msg, {bool error}) onMessage;

  const PostMatchStatsTab({
    super.key,
    required this.data,
    required this.service,
    required this.onUpdated,
    required this.onMessage,
  });

  @override
  State<PostMatchStatsTab> createState() => _PostMatchStatsTabState();
}

class _StatsEdit {
  int goals;
  int assists;
  int yellow;
  int red;
  int? minutes;

  _StatsEdit({
    required this.goals,
    required this.assists,
    required this.yellow,
    required this.red,
    this.minutes,
  });
}

class _PostMatchStatsTabState extends State<PostMatchStatsTab> {
  late Map<int, _StatsEdit> _stats;
  late Map<int, TextEditingController> _minutesControllers;
  late TextEditingController _teamScoreCtrl;
  late TextEditingController _oppScoreCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _minutesControllers = {};
    _teamScoreCtrl = TextEditingController(
      text: widget.data.matchResult.teamScore?.toString() ?? '',
    );
    _oppScoreCtrl = TextEditingController(
      text: widget.data.matchResult.opponentScore?.toString() ?? '',
    );
    _loadStats();
  }

  void _loadStats() {
    for (final c in _minutesControllers.values) {
      c.dispose();
    }
    _stats = {
      for (final s in widget.data.stats)
        s.userId: _StatsEdit(
          goals: s.goals,
          assists: s.assists,
          yellow: s.yellowCards,
          red: s.redCards,
          minutes: s.minutesPlayed,
        ),
    };
    _minutesControllers = {
      for (final s in widget.data.stats)
        s.userId: TextEditingController(
          text: s.minutesPlayed?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _teamScoreCtrl.dispose();
    _oppScoreCtrl.dispose();
    for (final c in _minutesControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? _parseScore(TextEditingController c) {
    final t = c.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final players = _stats.entries
          .map(
            (e) => {
              'userId': e.key,
              'goals': e.value.goals,
              'assists': e.value.assists,
              'yellowCards': e.value.yellow,
              'redCards': e.value.red,
              'minutesPlayed': () {
                final t = _minutesControllers[e.key]?.text.trim() ?? '';
                if (t.isEmpty) return null;
                return int.tryParse(t);
              }(),
            },
          )
          .toList();
      await widget.service.updateStats(
        widget.data.eventId,
        teamScore: _parseScore(_teamScoreCtrl),
        opponentScore: _parseScore(_oppScoreCtrl),
        players: players,
      );
      widget.onMessage('Estadísticas guardadas');
      widget.onUpdated();
    } catch (e) {
      widget.onMessage(PostMatchService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.stats.isEmpty) {
      return const Center(child: Text('Sin jugadores convocados'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (widget.data.canManage)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _teamScoreCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Nuestro equipo',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('-'),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _oppScoreCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      widget.data.opponentName ?? 'Rival',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          widget.data.matchResult.scoreLabel(
                            widget.data.opponentName ?? 'Rival',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.data.canManage)
                ...widget.data.stats.map((s) {
                  final edit = _stats[s.userId]!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.userName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StatStepper(
                                label: 'Goles',
                                value: edit.goals,
                                onChanged: (v) => setState(() => edit.goals = v),
                              ),
                              _StatStepper(
                                label: 'Asist.',
                                value: edit.assists,
                                onChanged: (v) =>
                                    setState(() => edit.assists = v),
                              ),
                              _StatStepper(
                                label: 'Amarillas',
                                value: edit.yellow,
                                onChanged: (v) =>
                                    setState(() => edit.yellow = v),
                              ),
                              _StatStepper(
                                label: 'Rojas',
                                value: edit.red,
                                onChanged: (v) => setState(() => edit.red = v),
                              ),
                              SizedBox(
                                width: 88,
                                child: TextField(
                                  controller: _minutesControllers[s.userId],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Min',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                })
              else
                ...widget.data.stats.map(
                  (s) => Card(
                    child: ListTile(
                      title: Text(s.userName),
                      subtitle: Text(
                        'G ${s.goals} · A ${s.assists} · '
                        '🟨 ${s.yellowCards} · 🟥 ${s.redCards}'
                        '${s.minutesPlayed != null ? ' · ${s.minutesPlayed}′' : ''}',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.data.canManage)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Guardar estadísticas'),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatStepper extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StatStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

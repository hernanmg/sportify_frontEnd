import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/post_match_service.dart';
import 'package:sportify_amateur/models/post_match.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class PostMatchScreen extends StatefulWidget {
  final int eventId;
  final String? eventTitle;

  const PostMatchScreen({
    super.key,
    required this.eventId,
    this.eventTitle,
  });

  @override
  State<PostMatchScreen> createState() => _PostMatchScreenState();
}

class _PostMatchScreenState extends State<PostMatchScreen>
    with SingleTickerProviderStateMixin {
  final _service = PostMatchService();
  late TabController _tabs;
  PostMatchData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getPostMatch(widget.eventId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PostMatchService.errorMessage(e);
        _loading = false;
      });
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _openVoteSheet() async {
    final data = _data;
    if (data == null || !data.canVote) return;

    final scores = <int, int>{
      for (final t in data.targets)
        if (t.myVote != null) t.userId: t.myVote!,
    };

    final result = await showModalBottomSheet<Map<int, int>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _VoteBottomSheet(
        eventId: widget.eventId,
        targets: data.targets,
        initialScores: scores,
        mode: _VoteMode.peer,
      ),
    );

    if (result == null || !mounted) return;
    await _load();
    _snack('Votos guardados');
  }

  Future<void> _openOfficialSheet() async {
    final data = _data;
    if (data == null || !data.canManage) return;

    final scores = <int, int>{
      for (final t in data.targets)
        if (t.officialScore != null) t.userId: t.officialScore!.round(),
    };

    final result = await showModalBottomSheet<Map<int, int>?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _VoteBottomSheet(
        eventId: widget.eventId,
        targets: data.targets,
        initialScores: scores,
        title: 'Notas oficiales (DT)',
        mode: _VoteMode.official,
      ),
    );

    if (result == null || !mounted) return;
    await _load();
    _snack('Notas oficiales guardadas');
  }

  Future<void> _closeVoting() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar votación'),
        content: const Text(
          'Los jugadores no podrán enviar más votos. Las notas oficiales del DT siguen editables.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.closeVoting(widget.eventId);
      await _load();
      _snack('Votación cerrada');
    } catch (e) {
      _snack(PostMatchService.errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?.title ?? widget.eventTitle ?? 'Post-partido';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Resumen'),
                  Tab(text: 'Asistencia'),
                  Tab(text: 'Más'),
                ],
              ),
      ),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    final data = _data;
    if (data == null) return null;
    if (data.canVote) {
      return FloatingActionButton.extended(
        onPressed: _openVoteSheet,
        icon: const Icon(Icons.how_to_vote),
        label: const Text('Votar'),
      );
    }
    return null;
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    if (!data.postMatchOpen) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Post-partido disponible cuando el partido finalice '
            '(estado completado o fecha pasada).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabs,
      children: [
        _SummaryTab(
          data: data,
          onVote: _openVoteSheet,
          onOfficial: _openOfficialSheet,
          onCloseVoting: _closeVoting,
          onRefresh: _load,
        ),
        _AttendanceTab(targets: data.targets),
        _ComingSoonTab(),
      ],
    );
  }
}

enum _VoteMode { peer, official }

class _SummaryTab extends StatelessWidget {
  final PostMatchData data;
  final VoidCallback onVote;
  final VoidCallback onOfficial;
  final VoidCallback onCloseVoting;
  final Future<void> Function() onRefresh;

  const _SummaryTab({
    required this.data,
    required this.onVote,
    required this.onOfficial,
    required this.onCloseVoting,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pom = data.playerOfMatch;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(data.eventDate);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pom != null) ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.amber.shade200,
                      child: Text(
                        pom.jerseyNumber?.toString() ??
                            pom.userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jugador del partido',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            pom.userName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (pom.displayScore != null)
                            Text(
                              'Nota ${pom.displayScore!.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.emoji_events, size: 40, color: Colors.amber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            '${data.opponentName ?? 'Rival'} · $dateStr',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (data.votingClosed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: const Text('Votación cerrada'),
                backgroundColor: Colors.grey.shade200,
              ),
            )
          else if (data.canVote)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tu voto: ${data.myVotesCount}/${data.votesExpected} jugadores',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Cualquier miembro del equipo puede votar, aunque no esté en la lista del partido.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
          if (data.canManage) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onOfficial,
                  icon: const Icon(Icons.gavel, size: 18),
                  label: const Text('Notas DT'),
                ),
                if (!data.votingClosed)
                  OutlinedButton.icon(
                    onPressed: onCloseVoting,
                    icon: const Icon(Icons.lock, size: 18),
                    label: const Text('Cerrar votación'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Resumen de puntuaciones',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (data.targets.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No hay jugadores en la lista del partido'),
              ),
            )
          else
            ...data.targets.map((t) => _PlayerScoreCard(row: t)),
        ],
      ),
    );
  }
}

class _PlayerScoreCard extends StatelessWidget {
  final PostMatchPlayerRow row;

  const _PlayerScoreCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final label = row.jerseyNumber != null
        ? '${row.userName} #${row.jerseyNumber}'
        : row.userName;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ScoreColumn(
                    title: 'Equipo',
                    subtitle: '${row.teamVoteCount} votos',
                    value: row.teamAvgScore,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScoreColumn(
                    title: 'DT',
                    subtitle: 'oficial',
                    value: row.officialScore,
                    color: Colors.green.shade700,
                  ),
                ),
                if (row.myVote != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScoreColumn(
                      title: 'Vos',
                      subtitle: 'tu voto',
                      value: row.myVote!.toDouble(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? value;
  final Color color;

  const _ScoreColumn({
    required this.title,
    required this.subtitle,
    this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value != null ? value!.toStringAsFixed(1) : '—',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  final List<PostMatchPlayerRow> targets;

  const _AttendanceTab({required this.targets});

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) {
      return const Center(child: Text('Sin jugadores convocados'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: targets.length,
      itemBuilder: (_, i) {
        final t = targets[i];
        final att = t.attended;
        IconData icon;
        Color color;
        String status;
        if (att == true) {
          icon = Icons.check_circle;
          color = Colors.green;
          status = 'Presente';
        } else if (att == false) {
          icon = Icons.cancel;
          color = Colors.red;
          status = 'Ausente';
        } else {
          icon = Icons.help_outline;
          color = Colors.grey;
          status = 'Sin registrar';
        }
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(t.userName),
          subtitle: Text(t.isConvoked ? 'Convocado' : 'No convocado'),
          trailing: Text(status),
        );
      },
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Estadísticas', Icons.bar_chart),
      ('Alineación', Icons.grid_view),
      ('Reseña', Icons.article),
      ('Foro', Icons.forum),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: items
          .map(
            (e) => Card(
              child: ListTile(
                leading: Icon(e.$2, color: Colors.grey),
                title: Text(e.$1),
                subtitle: const Text('Próximamente — Fase 2'),
                trailing: const Icon(Icons.lock_outline, size: 18),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _VoteBottomSheet extends StatefulWidget {
  final int eventId;
  final List<PostMatchPlayerRow> targets;
  final Map<int, int> initialScores;
  final String title;
  final _VoteMode mode;

  const _VoteBottomSheet({
    required this.eventId,
    required this.targets,
    required this.initialScores,
    this.title = 'Votar jugadores',
    this.mode = _VoteMode.peer,
  });

  @override
  State<_VoteBottomSheet> createState() => _VoteBottomSheetState();
}

class _VoteBottomSheetState extends State<_VoteBottomSheet> {
  late Map<int, int> _scores;
  final _service = PostMatchService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scores = Map.from(widget.initialScores);
    for (final t in widget.targets) {
      _scores.putIfAbsent(t.userId, () => 7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => Material(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: widget.targets.length,
                  itemBuilder: (_, i) {
                    final t = widget.targets[i];
                    final score = _scores[t.userId] ?? 7;
                    return ListTile(
                      title: Text(t.userName),
                      subtitle: Slider(
                        value: score.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: score.toString(),
                        onChanged: (v) {
                          setState(() {
                            _scores[t.userId] = v.round();
                          });
                        },
                      ),
                      trailing: Text(
                        '$score',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final ratings = _scores.entries
          .map((e) => {'ratedUserId': e.key, 'score': e.value})
          .toList();

      if (widget.mode == _VoteMode.peer) {
        await _service.submitVotes(widget.eventId, ratings);
      } else {
        await _service.setOfficialRatings(
          widget.eventId,
          ratings: ratings,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, _scores);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(PostMatchService.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Si el partido ya pasó o está completado.
bool sportEventPostMatchAvailable(SportEvent event) {
  if (event.type != SportEventType.match) return false;
  if (event.status == SportEventStatus.draft ||
      event.status == SportEventStatus.cancelled) {
    return false;
  }
  if (event.status == SportEventStatus.completed) return true;
  return event.eventDate.isBefore(DateTime.now());
}

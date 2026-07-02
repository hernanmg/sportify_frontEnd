import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/post_match_service.dart';
import 'package:sportify_amateur/features/sports/match_lineup_board_tab.dart';
import 'package:sportify_amateur/features/sports/post_match_manage_tabs.dart';
import 'package:sportify_amateur/widgets/google_style_lineup_field.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';
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
  final _reportCtrl = TextEditingController();
  bool _savingReport = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _reportCtrl.dispose();
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
        _reportCtrl.text = data.reportText ?? '';
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

  Future<void> _saveReport() async {
    final data = _data;
    if (data == null || !data.canManage) return;
    setState(() => _savingReport = true);
    try {
      await _service.updateReport(
        data.eventId,
        text: _reportCtrl.text.trim().isEmpty ? null : _reportCtrl.text.trim(),
      );
      await _load();
      _snack('Acta guardada');
    } catch (e) {
      _snack(PostMatchService.errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _savingReport = false);
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

  List<PostMatchPlayerRow> _peerVoteTargets(PostMatchData data) {
    if (data.currentUserId <= 0) return data.targets;
    return data.targets
        .where((t) => t.userId != data.currentUserId)
        .toList();
  }

  Future<void> _openVoteSheet() async {
    final data = _data;
    if (data == null || !data.canVote) return;

    final voteTargets = _peerVoteTargets(data);
    if (voteTargets.isEmpty) {
      _snack(
        'No hay jugadores convocados para puntuar. '
        'El DT debe armar el plantel del partido.',
        error: true,
      );
      return;
    }

    final scores = <int, int>{
      for (final t in voteTargets)
        if (t.myVote != null) t.userId: t.myVote!,
    };

    final result = await showModalBottomSheet<VoteSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _VoteBottomSheet(
        eventId: widget.eventId,
        targets: voteTargets,
        initialScores: scores,
        mode: _VoteMode.peer,
      ),
    );

    if (!mounted || result == null) return;
    if (result.success) {
      await _load();
      _snack(result.message ?? 'Puntuaciones guardadas');
    } else {
      _snack(result.message ?? 'No se pudieron guardar', error: true);
    }
  }

  Future<void> _pickPlayerOfMatch(List<PostMatchPlayerOfMatch> tied) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Empate en el puntaje. Elegí jugador del partido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...tied.map(
              (p) => ListTile(
                leading: PlayerAvatar(
                  avatarUrl: p.avatarUrl,
                  displayName: p.userName,
                  radius: 20,
                ),
                title: Text(p.userName),
                subtitle: p.displayScore != null
                    ? Text('Nota ${p.displayScore!.toStringAsFixed(1)}')
                    : null,
                onTap: () => Navigator.pop(ctx, p.userId),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    try {
      await _service.setOfficialRatings(
        widget.eventId,
        ratings: const [],
        playerOfMatchUserId: picked,
      );
      await _load();
      _snack('Jugador del partido definido');
    } catch (e) {
      _snack(PostMatchService.errorMessage(e), error: true);
    }
  }

  Future<void> _openOfficialSheet() async {
    final data = _data;
    if (data == null || !data.canManage) return;

    if (data.targets.isEmpty) {
      _snack('No hay jugadores en la lista del partido', error: true);
      return;
    }

    final scores = <int, int>{
      for (final t in data.targets)
        if (t.officialScore != null) t.userId: t.officialScore!.round(),
    };

    final result = await showModalBottomSheet<VoteSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _VoteBottomSheet(
        eventId: widget.eventId,
        targets: data.targets,
        initialScores: scores,
        title: 'Notas oficiales (DT)',
        mode: _VoteMode.official,
      ),
    );

    if (!mounted || result == null) return;
    if (result.success) {
      await _load();
      _snack(result.message ?? 'Notas oficiales guardadas');
    } else {
      _snack(result.message ?? 'No se pudieron guardar', error: true);
    }
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

  Future<void> _completeMatch() async {
    final data = _data;
    if (data == null || !data.canManage || data.isCompleted) return;

    var teamText = data.matchResult.teamScore?.toString() ?? '';
    var oppText = data.matchResult.opponentScore?.toString() ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar partido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Marcá el partido como completado. Se cierra la votación '
              'y se notifica al equipo.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: teamText,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Goles nuestros',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => teamText = v,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: oppText,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: data.opponentName ?? 'Rival',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => oppText = v,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    int? parseScore(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t);
    }

    final teamScore = parseScore(teamText);
    final oppScore = parseScore(oppText);

    if (ok != true) return;

    try {
      await _service.completeMatch(
        widget.eventId,
        teamScore: teamScore,
        opponentScore: oppScore,
      );
      await _load();
      _snack('Partido finalizado');
    } catch (e) {
      _snack(PostMatchService.errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventName = _data?.title ?? widget.eventTitle;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gestionar partido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (eventName != null && eventName.isNotEmpty)
              Text(
                eventName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
              ),
          ],
        ),
        actions: [
          if (_data?.canManage == true && _data?.isCompleted != true)
            IconButton(
              icon: const Icon(Icons.flag),
              tooltip: 'Finalizar partido',
              onPressed: _completeMatch,
            ),
        ],
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Resumen'),
                  Tab(text: 'Asistencia'),
                  Tab(text: 'Estadísticas'),
                  Tab(text: 'Alineación'),
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

    return Column(
      children: [
        if (!data.postMatchOpen && data.canManage)
          MaterialBanner(
            content: const Text(
              'Partido programado: podés cargar asistencia, alineación y '
              'estadísticas. La votación del plantel se habilita al finalizar.',
            ),
            actions: [
              if (!data.isCompleted)
                TextButton(
                  onPressed: _completeMatch,
                  child: const Text('Finalizar partido'),
                ),
            ],
          )
        else if (!data.postMatchOpen)
          MaterialBanner(
            content: const Text(
              'La votación se habilita cuando el partido finalice.',
            ),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: TabBarView(
      controller: _tabs,
      children: [
        _SummaryTab(
          data: data,
          onVote: _openVoteSheet,
          onOfficial: _openOfficialSheet,
          onCloseVoting: _closeVoting,
          onComplete: _completeMatch,
          onRefresh: _load,
          onPickPlayerOfMatch: _pickPlayerOfMatch,
        ),
        PostMatchAttendanceTab(
          data: data,
          service: _service,
          onUpdated: _load,
          onMessage: (msg, {error = false}) => _snack(msg, error: error),
        ),
        PostMatchStatsTab(
          data: data,
          service: _service,
          onUpdated: _load,
          onMessage: (msg, {error = false}) => _snack(msg, error: error),
        ),
        MatchLineupBoardTab(
          data: data,
          service: _service,
          onUpdated: _load,
          onMessage: (msg, {error = false}) => _snack(msg, error: error),
        ),
        _ReportTab(
          data: data,
          controller: _reportCtrl,
          saving: _savingReport,
          onSave: _saveReport,
        ),
      ],
          ),
        ),
      ],
    );
  }
}

enum _VoteMode { peer, official }

String _pomScoreLabel(PostMatchPlayerOfMatch pom) {
  final parts = <String>[];
  if (pom.teamAvgScore != null) {
    parts.add('plantel ${pom.teamAvgScore!.toStringAsFixed(1)}');
  }
  if (pom.officialScore != null) {
    parts.add('DT ${pom.officialScore!.toStringAsFixed(1)}');
  }
  final score = pom.displayScore?.toStringAsFixed(1) ?? '—';
  if (parts.isEmpty) return 'Nota $score';
  return 'Nota $score (${parts.join(' · ')})';
}

class _SummaryTab extends StatelessWidget {
  final PostMatchData data;
  final VoidCallback onVote;
  final VoidCallback onOfficial;
  final VoidCallback onCloseVoting;
  final VoidCallback onComplete;
  final Future<void> Function() onRefresh;
  final void Function(List<PostMatchPlayerOfMatch> tied) onPickPlayerOfMatch;

  const _SummaryTab({
    required this.data,
    required this.onVote,
    required this.onOfficial,
    required this.onCloseVoting,
    required this.onComplete,
    required this.onRefresh,
    required this.onPickPlayerOfMatch,
  });

  @override
  Widget build(BuildContext context) {
    final pom = data.playerOfMatch;
    final tied = data.playerOfMatchTied;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(data.eventDate);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Jugador del partido',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.emoji_events,
                          size: 32, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (pom != null)
                    Row(
                      children: [
                        PlayerAvatar(
                          avatarUrl: pom.avatarUrl,
                          displayName: pom.userName,
                          radius: 28,
                          badgeText: pom.jerseyNumber?.toString(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pom.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              if (pom.displayScore != null)
                                Text(
                                  _pomScoreLabel(pom),
                                  style: TextStyle(color: Colors.amber.shade900),
                                ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (tied.length > 1) ...[
                    Text(
                      'Empate (${tied.length} jugadores)',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tied
                          .map(
                            (p) => Chip(
                              avatar: PlayerAvatar(
                                avatarUrl: p.avatarUrl,
                                displayName: p.userName,
                                radius: 14,
                              ),
                              label: Text(
                                '${p.userName}${p.displayScore != null ? ' (${p.displayScore!.toStringAsFixed(1)})' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (data.canManage) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => onPickPlayerOfMatch(tied),
                        child: const Text('Definir jugador del partido'),
                      ),
                    ],
                  ] else
                    Text(
                      data.isCompleted
                          ? 'Sin definir'
                          : 'Se define al finalizar el partido',
                      style: TextStyle(color: Colors.amber.shade900),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${data.opponentName ?? 'Rival'} · $dateStr',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (data.matchResult.teamScore != null &&
              data.matchResult.opponentScore != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                data.matchResult.scoreLabel(data.opponentName ?? 'Rival'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          if (data.isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: const Text('Partido finalizado'),
                backgroundColor: Colors.green.shade100,
              ),
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
            )
          else if (data.postMatchOpen &&
              !data.votingClosed &&
              data.votesExpected > 0 &&
              data.myVotesCount >= data.votesExpected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: const Text('Ya enviaste tu votación'),
                backgroundColor: Colors.green.shade100,
              ),
            ),
          const SizedBox(height: 8),
          if (data.canVote)
            Text(
              'Como jugador convocado podés puntuar a tus compañeros del partido.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            )
          else if (!data.votingClosed && data.postMatchOpen && data.isCompleted)
            Text(
              'La votación está abierta para jugadores convocados.',
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
                if (!data.votingClosed && data.postMatchOpen)
                  OutlinedButton.icon(
                    onPressed: onCloseVoting,
                    icon: const Icon(Icons.lock, size: 18),
                    label: const Text('Cerrar votación'),
                  ),
                if (!data.isCompleted)
                  FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.flag, size: 18),
                    label: const Text('Finalizar partido'),
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
          if (data.lineup.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Alineación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 480,
              child: GoogleStyleLineupField.fromPostMatch(data),
            ),
          ],
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
            Row(
              children: [
                PlayerAvatar(
                  avatarUrl: row.avatarUrl,
                  displayName: row.userName,
                  radius: 18,
                  badgeText: row.jerseyNumber?.toString(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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

class _ReportTab extends StatelessWidget {
  final PostMatchData data;
  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;

  const _ReportTab({
    required this.data,
    required this.controller,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final readOnly = !data.canManage;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Acta / Reseña',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Usá este espacio para dejar un resumen del partido: '
          'plan, objetivos, jugadas clave, decisiones, aprendizajes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          readOnly: readOnly,
          minLines: 10,
          maxLines: 18,
          decoration: InputDecoration(
            hintText: readOnly
                ? 'Sin acta cargada.'
                : 'Escribí el acta del partido…',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (data.reportUpdatedAt != null)
          Text(
            'Última edición: ${DateFormat('dd/MM/yyyy HH:mm').format(data.reportUpdatedAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 12),
        if (data.canManage)
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Guardar acta'),
          ),
      ],
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
  String? _error;

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
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: maxH,
      child: Material(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: widget.targets.length,
                itemBuilder: (_, i) {
                  final t = widget.targets[i];
                  final score = _scores[t.userId] ?? 7;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$score',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: score.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: score.toString(),
                            onChanged: _saving
                                ? null
                                : (v) {
                                    setState(() {
                                      _scores[t.userId] = v.round();
                                      _error = null;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar puntuaciones'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (widget.targets.isEmpty) {
      setState(() => _error = 'No hay jugadores para puntuar');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

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
      Navigator.pop(
        context,
        VoteSheetResult(
          success: true,
          message: widget.mode == _VoteMode.peer
              ? 'Puntuaciones guardadas'
              : 'Notas oficiales guardadas',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(
        context,
        VoteSheetResult(
          success: false,
          message: PostMatchService.errorMessage(e),
        ),
      );
    }
  }
}

/// Convocatoria enviada (o posterior): se puede abrir post-partido.
bool canOpenPostMatch(SportEvent event) {
  if (event.type != SportEventType.match) return false;
  if (event.status == SportEventStatus.draft ||
      event.status == SportEventStatus.cancelled) {
    return false;
  }
  return true;
}

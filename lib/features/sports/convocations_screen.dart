import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/convocations_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/core/services/convocation_pdf_service.dart';
import 'package:sportify_amateur/features/sports/convocation_form_screen.dart';
import 'package:sportify_amateur/features/sports/post_match_screen.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class ConvocationsScreen extends StatefulWidget {
  const ConvocationsScreen({super.key});

  @override
  State<ConvocationsScreen> createState() => ConvocationsScreenState();
}

class ConvocationsScreenState extends State<ConvocationsScreen> {
  final _convocationsService = ConvocationsService();
  final _pdfService = ConvocationPdfService();
  final _teamService = TeamService();

  List<MyTeamOption> _teams = [];
  MyTeamOption? _selectedTeam;
  List<SportEvent> _convocations = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
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
      final selected = (previousId != null
              ? MyTeamOption.findInList(teams, previousId)
              : null) ??
          (teams.isNotEmpty ? teams.first : null);
      List<SportEvent> list = [];
      if (selected != null) {
        list = await _convocationsService.getAllConvocations(
          teamId: selected.teamId,
        );
      }
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _selectedTeam = selected;
        _convocations = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<SportEvent> get _filtered {
    switch (_filter) {
      case 'sent':
        return ConvocationsService.filterSent(_convocations);
      case 'draft':
        return ConvocationsService.filterDrafts(_convocations);
      case 'official':
        return ConvocationsService.filterByMatchType(_convocations, true);
      case 'friendly':
        return ConvocationsService.filterByMatchType(_convocations, false);
      default:
        return _convocations;
    }
  }

  Future<void> _openCreate({bool official = false}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConvocationFormScreen(isOfficial: official),
      ),
    );
    if (result == true) await _load();
  }

  Future<void> _send(SportEvent c) async {
    try {
      await _convocationsService.sendConvocation(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Convocatoria enviada'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showResponses(SportEvent c) async {
    try {
      final stats = await _convocationsService.getConvocationStats(c.id);
      final responses =
          await _convocationsService.getConvocationResponses(c.id);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(c.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convocados: ${stats.convoked} · Confirmados: ${stats.confirmed} · Pendientes: ${stats.pending}',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: responses.map((p) {
                      final convoked = p.isConvoked ? '✓' : '–';
                      return ListTile(
                        dense: true,
                        leading: PlayerAvatar(
                          avatarUrl: p.avatarUrl,
                          displayName: p.userName,
                          radius: 16,
                        ),
                        title: Text('$convoked ${p.userName}'),
                        subtitle: Text(
                          '${p.statusDisplayName}${p.eligibilityDetail != null ? ' · ${p.eligibilityDetail}' : ''}',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_teams.isNotEmpty)
                DropdownButtonFormField<MyTeamOption>(
                  value: _selectedTeam != null &&
                          _teams.any((t) => t.teamId == _selectedTeam!.teamId)
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
                    await _load();
                  },
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filter,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todas')),
                        DropdownMenuItem(
                          value: 'sent',
                          child: Text('Enviadas'),
                        ),
                        DropdownMenuItem(
                          value: 'draft',
                          child: Text('Borradores'),
                        ),
                        DropdownMenuItem(
                          value: 'official',
                          child: Text('Oficiales'),
                        ),
                        DropdownMenuItem(
                          value: 'friendly',
                          child: Text('Amistosos'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _filter = v ?? 'all'),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add_circle_outline),
                    onSelected: (v) {
                      if (v == 'official') {
                        _openCreate(official: true);
                      } else {
                        _openCreate(official: false);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'friendly',
                        child: Text('Amistoso'),
                      ),
                      PopupMenuItem(
                        value: 'official',
                        child: Text('Oficial'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text('No hay convocatorias'),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final c = _filtered[i];
                            final isDraft =
                                c.status == SportEventStatus.draft;
                            final dateStr =
                                DateFormat('dd/MM/yyyy HH:mm').format(
                              c.eventDate,
                            );
                            return Card(
                              child: ExpansionTile(
                                leading: Icon(
                                  c.isOfficialMatch
                                      ? Icons.emoji_events
                                      : Icons.sports_soccer,
                                  color: isDraft
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                title: Text(c.title),
                                subtitle: Text(
                                  '${c.opponentName ?? 'Rival'} · $dateStr',
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (c.location != null)
                                          Text('📍 ${c.location}'),
                                        if (c.courtNumber != null)
                                          Text('Cancha ${c.courtNumber}'),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            Chip(
                                              label: Text(
                                                isDraft
                                                    ? 'Borrador'
                                                    : 'Enviada',
                                              ),
                                              backgroundColor: isDraft
                                                  ? Colors.orange.shade100
                                                  : Colors.green.shade100,
                                            ),
                                            Chip(
                                              label: Text(
                                                c.isOfficialMatch
                                                    ? 'Oficial'
                                                    : 'Amistoso',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (!isDraft && canOpenPostMatch(c))
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: FilledButton.tonalIcon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PostMatchScreen(
                                                        eventId: c.id,
                                                        eventTitle: c.title,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.emoji_events_outlined,
                                                ),
                                                label: const Text(
                                                  'Post-partido',
                                                ),
                                              ),
                                            ),
                                          ),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            if (isDraft)
                                              TextButton.icon(
                                                onPressed: () => _send(c),
                                                icon: const Icon(Icons.send),
                                                label: const Text('Enviar'),
                                              ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _showResponses(c),
                                              icon: const Icon(Icons.people),
                                              label: const Text('Plantel'),
                                            ),
                                            if (!isDraft)
                                              TextButton.icon(
                                                onPressed: () async {
                                                  try {
                                                    await _pdfService
                                                        .previewPdf(c.id);
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'PDF: $e',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.picture_as_pdf,
                                                ),
                                                label: const Text('PDF'),
                                              ),
                                            if (isDraft)
                                              TextButton.icon(
                                                onPressed: () async {
                                                  final r =
                                                      await Navigator.push<
                                                          bool>(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ConvocationFormScreen(
                                                        existing: c,
                                                        isOfficial: c
                                                            .isOfficialMatch,
                                                      ),
                                                    ),
                                                  );
                                                  if (r == true) await _load();
                                                },
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Editar'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/convocations_service.dart';
import 'package:sportify_amateur/core/services/convocation_template_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/convocation_template.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/team_category_pick.dart';
import 'package:sportify_amateur/models/player_eligibility.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class ConvocationFormScreen extends StatefulWidget {
  final SportEvent? existing;
  final bool isOfficial;

  const ConvocationFormScreen({
    super.key,
    this.existing,
    this.isOfficial = false,
  });

  @override
  State<ConvocationFormScreen> createState() => _ConvocationFormScreenState();
}

class _ConvocationFormScreenState extends State<ConvocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _convocationsService = ConvocationsService();
  final _templateService = ConvocationTemplateService();
  final _teamService = TeamService();

  final _titleController = TextEditingController();
  final _opponentController = TextEditingController();
  final _locationController = TextEditingController();
  final _courtController = TextEditingController();
  final _notesController = TextEditingController();

  List<TeamCategoryPick> _teamPicks = [];
  TeamCategoryPick? _selectedPick;
  DateTime _matchDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _matchTime = const TimeOfDay(hour: 16, minute: 0);
  bool _isOfficial = false;
  bool _isHome = true;

  SportEvent? _draft;
  List<PlayerEligibility> _roster = [];
  final Set<int> _convokedIds = {};
  List<ConvocationTemplate> _templates = [];
  bool _loading = false;
  bool _loadingRoster = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _isOfficial = widget.isOfficial;
    _loadTeams();
    if (widget.existing != null) {
      _draft = widget.existing;
      _fillFromDraft(widget.existing!);
      _step = 1;
      _loadRoster();
    }
  }

  Future<void> _loadTeams() async {
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
      final picks = TeamCategoryPick.fromMyTeams(teams);
      final draftTeamId = widget.existing?.teamId ?? _draft?.teamId;
      final meta = widget.existing?.metadata ?? _draft?.metadata;
      final draftCatId = meta?['categoryId'] as int?;
      final selected = (draftTeamId != null
              ? TeamCategoryPick.findForTeam(
                  picks,
                  draftTeamId,
                  categoryId: draftCatId,
                )
              : null) ??
          (picks.isNotEmpty ? picks.first : null);
      setState(() {
        _teamPicks = picks;
        _selectedPick = selected;
      });
    } catch (_) {}
  }

  void _fillFromDraft(SportEvent e) {
    _titleController.text = e.title;
    _opponentController.text = e.opponentName ?? '';
    _locationController.text = e.location ?? '';
    _courtController.text = e.courtNumber ?? '';
    _notesController.text = e.notes ?? '';
    _matchDate = e.eventDate;
    _matchTime = TimeOfDay.fromDateTime(e.eventDate);
    _isOfficial = e.isOfficialMatch;
    _isHome = e.isHomeMatch;
  }

  Future<void> _loadTemplates() async {
    final teamId = _selectedPick?.teamId ?? _draft?.teamId;
    if (teamId == null) return;
    try {
      final list = await _templateService.list(teamId);
      if (mounted) setState(() => _templates = list);
    } catch (_) {
      if (mounted) setState(() => _templates = []);
    }
  }

  void _applyTemplate(ConvocationTemplate? t) {
    if (t == null) return;
    setState(() {
      _convokedIds
        ..clear()
        ..addAll(t.defaultParticipantUserIds);
    });
  }

  Future<void> _saveAsTemplate() async {
    final teamId = _selectedPick?.teamId ?? _draft?.teamId;
    if (teamId == null || _convokedIds.isEmpty) return;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Guardar plantilla'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    try {
      await _templateService.create(
        teamId,
        name: name,
        defaultParticipantUserIds: _convokedIds.toList(),
      );
      await _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadRoster() async {
    if (_draft == null) return;
    setState(() => _loadingRoster = true);
    try {
      final roster = await _convocationsService.getEligibleRoster(_draft!.id);
      final convoked = _draft!.participants
          .where((p) => p.isConvoked)
          .map((p) => p.userId)
          .toSet();
      setState(() {
        _roster = roster;
        _convokedIds
          ..clear()
          ..addAll(
            convoked.isEmpty ? roster.map((e) => e.userId) : convoked,
          );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar plantel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRoster = false);
    }
    await _loadTemplates();
  }

  Future<void> _createDraft() async {
    if (!_formKey.currentState!.validate() || _selectedPick == null) return;

    setState(() => _loading = true);
    try {
      final dt = DateTime(
        _matchDate.year,
        _matchDate.month,
        _matchDate.day,
        _matchTime.hour,
        _matchTime.minute,
      );
      final payload = {
        'title': _titleController.text.trim(),
        'teamId': _selectedPick!.teamId,
        if (_selectedPick!.categoryId != null)
          'categoryId': _selectedPick!.categoryId,
        'eventDate': dt.toIso8601String(),
        'opponentName': _opponentController.text.trim(),
        'location': _locationController.text.trim(),
        'courtNumber': _courtController.text.trim().isEmpty
            ? null
            : _courtController.text.trim(),
        'isHomeMatch': _isHome,
        'isOfficialMatch': _isOfficial,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      final created = _isOfficial
          ? await _convocationsService.createOfficialMatch(payload)
          : await _convocationsService.createFriendlyMatch(payload);

      setState(() {
        _draft = created;
        _step = 1;
      });
      await _loadRoster();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSquad({required bool send}) async {
    if (_draft == null) return;
    if (_convokedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná al menos un jugador convocado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _convocationsService.setSquad(
        _draft!.id,
        convokedUserIds: _convokedIds.toList(),
      );
      if (send) {
        await _convocationsService.sendConvocation(_draft!.id);
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final nav = Navigator.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              send
                  ? 'Convocatoria enviada al plantel'
                  : 'Borrador guardado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        nav.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _opponentController.dispose();
    _locationController.dispose();
    _courtController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing != null
              ? 'Editar convocatoria'
              : (_isOfficial ? 'Partido oficial' : 'Partido amistoso'),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _step == 0 ? _buildStepMatch() : _buildStepSquad(),
    );
  }

  Widget _buildStepMatch() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_teamPicks.isEmpty)
            const Text('No tenés equipos asignados.')
          else
            DropdownButtonFormField<TeamCategoryPick>(
              value: _selectedPick != null &&
                      _teamPicks.any(
                        (p) =>
                            p.teamId == _selectedPick!.teamId &&
                            p.categoryId == _selectedPick!.categoryId,
                      )
                  ? _selectedPick
                  : null,
              decoration: const InputDecoration(
                labelText: 'Equipo y categoría',
                border: OutlineInputBorder(),
              ),
              items: _teamPicks
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedPick = v),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _opponentController,
            decoration: const InputDecoration(
              labelText: 'Rival *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _matchDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _matchDate = d);
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd/MM/yyyy').format(_matchDate)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _matchTime,
                    );
                    if (t != null) setState(() => _matchTime = t);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(_matchTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Lugar (estadio / predio) *',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _courtController,
            decoration: const InputDecoration(
              labelText: 'Número de cancha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Partido en casa'),
            value: _isHome,
            onChanged: (v) => setState(() => _isHome = v),
          ),
          SwitchListTile(
            title: const Text('Partido oficial'),
            value: _isOfficial,
            onChanged: (v) => setState(() => _isOfficial = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _createDraft,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continuar — elegir plantel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepSquad() {
    return Column(
      children: [
        if (_templates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ConvocationTemplate>(
                    decoration: const InputDecoration(
                      labelText: 'Plantilla',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _templates
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              '${t.name} (${t.defaultParticipantUserIds.length})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _applyTemplate,
                  ),
                ),
                IconButton(
                  tooltip: 'Guardar plantilla actual',
                  onPressed: _saveAsTemplate,
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Plantel (${_convokedIds.length}/${_roster.length} convocados)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _convokedIds
                      ..clear()
                      ..addAll(_roster.map((e) => e.userId));
                  });
                },
                child: const Text('Todos'),
              ),
              TextButton(
                onPressed: () => setState(() => _convokedIds.clear()),
                child: const Text('Ninguno'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingRoster
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _roster.length,
                  itemBuilder: (context, i) {
                    final p = _roster[i];
                    final selected = _convokedIds.contains(p.userId);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _convokedIds.add(p.userId);
                          } else {
                            _convokedIds.remove(p.userId);
                          }
                        });
                      },
                      title: Text(
                        '#${p.jerseyNumber ?? '–'} ${p.playerName}',
                      ),
                      subtitle: Text(
                        '${p.statusEmoji} ${p.statusLabel} — ${p.reason}',
                        style: TextStyle(
                          color: p.isEligible
                              ? Colors.green.shade700
                              : Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                      secondary: PlayerAvatar(
                        avatarUrl: p.avatarUrl,
                        displayName: p.playerName,
                        radius: 20,
                        backgroundColor: p.color.materialColor.withValues(
                          alpha: 0.2,
                        ),
                        badgeText: '${p.jerseyNumber ?? '?'}',
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () => _saveSquad(send: false),
                    child: const Text('Guardar borrador'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _loading ? null : () => _saveSquad(send: true),
                    child: const Text('Enviar convocatoria'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

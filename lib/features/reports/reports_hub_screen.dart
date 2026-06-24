import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/services/team_extras_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/widgets/season_selector_chip.dart';

class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  final _extras = TeamExtrasService();
  final _teamService = TeamService();

  List<MyTeamOption> _teams = [];
  int? _teamId;
  int? _categoryId;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SeasonProvider>().addListener(_onSeasonChanged);
      }
    });
  }

  void _onSeasonChanged() {
    if (_teamId != null) _load();
  }

  @override
  void dispose() {
    try {
      context.read<SeasonProvider>().removeListener(_onSeasonChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _teamId = teams.isNotEmpty ? teams.first.teamId : null;
      });
      if (_teamId != null) {
        await _load();
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = TeamExtrasService.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    final teamId = _teamId;
    if (teamId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final season = context.read<SeasonProvider>().season;
      final data = await _extras.getReports(
        teamId,
        season: season,
        categoryId: _categoryId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TeamExtrasService.errorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendance =
        (_data?['attendance'] as List<dynamic>?) ?? const [];
    final debts = (_data?['debts'] as List<dynamic>?) ?? const [];
    final convocations =
        (_data?['convocations'] as List<dynamic>?) ?? const [];
    final playerConvocations =
        (_data?['playerConvocations'] as List<dynamic>?) ?? const [];
    final attendanceSessions =
        (_data?['attendanceSessions'] as List<dynamic>?) ?? const [];
    final sessionDateFmt = DateFormat('EEE d/M', 'es');
    final selectedTeam = _teams.where((t) => t.teamId == _teamId).toList();
    final team = selectedTeam.isNotEmpty ? selectedTeam.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: const [
          SeasonSelectorChip(),
          SizedBox(width: 8),
        ],
      ),
      body: _teams.isEmpty
          ? const Center(child: Text('No tenés equipos asignados'))
          : Column(
              children: [
                if (_teams.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      value: _teamId,
                      decoration: const InputDecoration(
                        labelText: 'Equipo',
                        border: OutlineInputBorder(),
                      ),
                      items: _teams
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.teamId,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _teamId = v;
                          _categoryId = null;
                        });
                        _load();
                      },
                    ),
                  ),
                if (team != null && team.categoryIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: DropdownButtonFormField<int?>(
                      value: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ...List.generate(team.categoryIds.length, (i) {
                          final id = team.categoryIds[i];
                          final name = i < team.categories.length
                              ? team.categories[i]
                              : 'Cat $id';
                          return DropdownMenuItem<int?>(
                            value: id,
                            child: Text(name),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setState(() => _categoryId = v);
                        _load();
                      },
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(_error!))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _sectionTitle('Asistencia %'),
                                  if (attendance.isEmpty)
                                    const Text('Sin datos aún'),
                                  ...attendance.map((row) {
                                    final m =
                                        Map<String, dynamic>.from(row as Map);
                                    final pct = m['attendancePct'];
                                    return ListTile(
                                      title: Text(
                                        m['userName']?.toString() ??
                                            'Usuario ${m['userId']}',
                                      ),
                                      subtitle: Text(
                                        'Presente ${m['present']} · Ausente ${m['absent']} · Justificado ${m['justified']}',
                                      ),
                                      trailing: Text(
                                        pct != null ? '$pct%' : '—',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }),
                                  const Divider(height: 32),
                                  _sectionTitle('Historial de sesiones'),
                                  if (attendanceSessions.isEmpty)
                                    const Text('Sin entrenamientos o partidos recientes'),
                                  ...attendanceSessions.map((row) {
                                    final m =
                                        Map<String, dynamic>.from(row as Map);
                                    final dateStr = m['eventDate']?.toString();
                                    DateTime? dt;
                                    if (dateStr != null) {
                                      dt = DateTime.tryParse(dateStr);
                                    }
                                    final type = m['type']?.toString() ?? '';
                                    final typeLabel = type == 'training'
                                        ? 'Entreno'
                                        : type == 'match'
                                            ? 'Partido'
                                            : type;
                                    return ListTile(
                                      title: Text(m['title']?.toString() ?? ''),
                                      subtitle: Text(
                                        '${dt != null ? sessionDateFmt.format(dt.toLocal()) : '—'} · $typeLabel · Presente ${m['present']} · Ausente ${m['absent']}',
                                      ),
                                      trailing: Text(
                                        m['attendancePct'] != null
                                            ? '${m['attendancePct']}%'
                                            : '—',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                  const Divider(height: 32),
                                  _sectionTitle('Deuda por jugador'),
                                  if (debts.isEmpty)
                                    const Text('Sin cargos registrados'),
                                  ...debts.map((row) {
                                    final m =
                                        Map<String, dynamic>.from(row as Map);
                                    final balance =
                                        (m['balance'] as num?)?.toDouble() ??
                                            0;
                                    return ListTile(
                                      title: Text(
                                        m['userName']?.toString() ?? '—',
                                      ),
                                      trailing: Text(
                                        '\$${balance.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: balance > 0
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                  const Divider(height: 32),
                                  _sectionTitle('Confirmaciones por jugador'),
                                  if (playerConvocations.isEmpty)
                                    const Text('Sin convocatorias registradas'),
                                  ...playerConvocations.map((row) {
                                    final m =
                                        Map<String, dynamic>.from(row as Map);
                                    return ListTile(
                                      title: Text(
                                        m['userName']?.toString() ?? '—',
                                      ),
                                      subtitle: Text(
                                        'Convocado ${m['timesConvoked']} veces · Confirmó ${m['confirmed']} · Rechazó ${m['declined'] ?? 0}',
                                      ),
                                      trailing: Text(
                                        '${m['confirmationRate']}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                  const Divider(height: 32),
                                  _sectionTitle('Convocatorias respondidas'),
                                  if (convocations.isEmpty)
                                    const Text('Sin partidos recientes'),
                                  ...convocations.map((row) {
                                    final m =
                                        Map<String, dynamic>.from(row as Map);
                                    return ListTile(
                                      title: Text(m['title']?.toString() ?? ''),
                                      subtitle: Text(
                                        'Convocados ${m['convoked']} · Respondieron ${m['responded']} · Confirmados ${m['confirmed']}',
                                      ),
                                      trailing: Text(
                                        '${m['responsePct']}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

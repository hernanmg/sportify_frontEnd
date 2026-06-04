import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/team_extras_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _extras = TeamExtrasService();
  final _teamService = TeamService();
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  List<MyTeamOption> _teams = [];
  int? _teamId;
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _teamId = teams.isNotEmpty ? teams.first.teamId : null;
      });
      if (_teamId != null) await _load();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    final teamId = _teamId;
    if (teamId == null) return;
    setState(() => _loading = true);
    try {
      final list = await _extras.getAuditLog(teamId);
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
      );
    }
  }

  String _actorName(Map<String, dynamic> entry) {
    final actor = entry['actor'];
    if (actor is Map) {
      final first = actor['firstName']?.toString() ?? '';
      final last = actor['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
    }
    return 'Sistema';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: _teams.isEmpty
          ? const Center(child: Text('No tenés equipos'))
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
                        setState(() => _teamId = v);
                        _load();
                      },
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _entries.isEmpty
                          ? const Center(
                              child: Text('Sin registros de auditoría'),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _entries.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final e = _entries[i];
                                  final created = e['createdAt']?.toString();
                                  DateTime? dt;
                                  if (created != null) {
                                    dt = DateTime.tryParse(created);
                                  }
                                  return ListTile(
                                    title: Text(
                                      e['summary']?.toString() ?? '—',
                                    ),
                                    subtitle: Text(
                                      '${_actorName(e)} · ${e['action'] ?? e['entityType'] ?? ''}',
                                    ),
                                    trailing: dt != null
                                        ? Text(
                                            _dateFmt.format(dt.toLocal()),
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          )
                                        : null,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}

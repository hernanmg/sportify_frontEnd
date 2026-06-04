import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_extras_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

class SponsorsScreen extends StatefulWidget {
  const SponsorsScreen({super.key});

  @override
  State<SponsorsScreen> createState() => _SponsorsScreenState();
}

class _SponsorsScreenState extends State<SponsorsScreen> {
  final _extras = TeamExtrasService();
  final _teamService = TeamService();

  List<MyTeamOption> _teams = [];
  int? _teamId;
  List<Map<String, dynamic>> _sponsors = [];
  bool _loading = true;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = await AuthStorageService().getRole();
    _isStaff = role == 'super_admin' ||
        role == 'manager' ||
        role == 'admin' ||
        role == 'team_captain' ||
        role == 'dt';
    try {
      final teams = MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _teamId = teams.isNotEmpty ? teams.first.teamId : null;
      });
      if (_teamId != null) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _load() async {
    final teamId = _teamId;
    if (teamId == null) return;
    setState(() => _loading = true);
    try {
      final list = await _extras.getSponsors(teamId);
      if (!mounted) return;
      setState(() {
        _sponsors = list;
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

  Future<void> _addSponsor() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final webController = TextEditingController();
    final amountController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo sponsor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: webController,
                decoration: const InputDecoration(labelText: 'Sitio web'),
              ),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Aporte (\$)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true || _teamId == null) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await _extras.createSponsor(
        _teamId!,
        name: name,
        description: descController.text.trim(),
        website: webController.text.trim(),
        amountContributed: double.tryParse(amountController.text.trim()),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamExtrasService.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsors'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _isStaff && _teamId != null
          ? FloatingActionButton(
              onPressed: _addSponsor,
              child: const Icon(Icons.add),
            )
          : null,
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
                      : _sponsors.isEmpty
                          ? const Center(
                              child: Text('Aún no hay sponsors cargados'),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _sponsors.length,
                                itemBuilder: (_, i) {
                                  final s = _sponsors[i];
                                  final amount = s['amountContributed'];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          (s['name'] as String?)
                                                  ?.substring(0, 1)
                                                  .toUpperCase() ??
                                              '?',
                                        ),
                                      ),
                                      title: Text(s['name']?.toString() ?? ''),
                                      subtitle: Text(
                                        [
                                          if (s['description'] != null)
                                            s['description'],
                                          if (s['website'] != null)
                                            s['website'],
                                        ].join('\n'),
                                      ),
                                      trailing: amount != null
                                          ? Text('\$$amount')
                                          : null,
                                    ),
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

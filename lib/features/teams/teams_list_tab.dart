import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/core/widgets/team_logo_avatar.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';

class TeamsListTab extends StatefulWidget {
  const TeamsListTab({super.key});

  @override
  TeamsListTabState createState() => TeamsListTabState();
}

class TeamsListTabState extends State<TeamsListTab> {
  final TeamService _teamService = TeamService();
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  Set<int> _myTeamIds = {};
  bool _isLoading = true;
  bool _isPlatformAdmin = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> reload() => _loadTeams();

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final role = await AuthStorageService().getRole();
      final myTeams = await _teamService.getMyTeams();
      final teams = await _teamService.getAllTeams();
      setState(() {
        _isPlatformAdmin =
            role == 'super_admin' || role == 'manager' || role == 'admin';
        _myTeamIds = myTeams.map((t) => t.teamId).toSet();
        _teams = teams;
        _filteredTeams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar equipos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTeams(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTeams = _teams;
      } else {
        _filteredTeams = _teams.where((team) {
          return team.name.toLowerCase().contains(query.toLowerCase()) ||
              (team.sport?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (team.category?.toLowerCase().contains(query.toLowerCase()) ??
                  false);
        }).toList();
      }
    });
  }

  Future<void> _addTeam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TeamFormScreen()),
    );
    if (result != null) {
      _loadTeams();
    }
  }

  Future<void> _editTeam(Team team) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeamFormScreen(team: team)),
    );
    if (result != null) {
      _loadTeams();
    }
  }

  Future<void> _claimTeam(Team team) async {
    try {
      final result = await _teamService.claimTeamAsAdmin(team.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Te asignaste a ${team.name}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadTeams();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TeamService.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTeam(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el equipo "${team.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _teamService.deleteTeam(team.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Equipo "${team.name}" eliminado'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadTeams();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _canClaim(Team team) =>
      _isPlatformAdmin && !_myTeamIds.contains(team.id);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar equipos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _filterTeams,
              ),
              if (_isPlatformAdmin) ...[
                const SizedBox(height: 8),
                Text(
                  'Si creaste un equipo y no aparece en Inicio, usá ⋮ → Asignarme como encargado.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTeams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay equipos registrados'
                                : 'Sin resultados para "$_searchQuery"',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addTeam,
                            icon: const Icon(Icons.add),
                            label: const Text('Crear equipo'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTeams,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = _filteredTeams[index];
                          final isMine = _myTeamIds.contains(team.id);
                          return Card(
                            child: ListTile(
                              leading: TeamLogoAvatar(
                                logoUrl: team.logoUrl,
                                colorsRaw: team.colors,
                                radius: 24,
                                highlight: isMine,
                              ),
                              title: Text(Team.listLabel(team, _teams)),
                              subtitle: Text(
                                [
                                  'ID ${team.id}',
                                  team.sport,
                                  team.categoryNames.isNotEmpty
                                      ? team.categoryNames.join(', ')
                                      : team.category,
                                  if (isMine) 'Ya asignado',
                                ].whereType<String>().join(' • '),
                              ),
                              onTap: () => _editTeam(team),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editTeam(team);
                                  } else if (value == 'delete') {
                                    _deleteTeam(team);
                                  } else if (value == 'claim') {
                                    _claimTeam(team);
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (_canClaim(team))
                                    const PopupMenuItem(
                                      value: 'claim',
                                      child: Text('Asignarme como encargado'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
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

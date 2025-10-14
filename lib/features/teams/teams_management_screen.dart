import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';

class TeamsManagementScreen extends StatefulWidget {
  const TeamsManagementScreen({super.key});

  @override
  State<TeamsManagementScreen> createState() => _TeamsManagementScreenState();
}

class _TeamsManagementScreenState extends State<TeamsManagementScreen> {
  final TeamService _teamService = TeamService();
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await _teamService.getAllTeams();
      setState(() {
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
      MaterialPageRoute(
        builder: (context) => const TeamFormScreen(),
      ),
    );
    if (result == true) {
      _loadTeams();
    }
  }

  Future<void> _editTeam(Team team) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamFormScreen(team: team),
      ),
    );
    if (result == true) {
      _loadTeams();
    }
  }

  Future<void> _deleteTeam(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el equipo "${team.name}"?\n\n'
          'Esta acción no se puede deshacer y eliminará también todos los registros '
          'de la lista de buena fe asociados.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTeam,
            tooltip: 'Agregar Equipo',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Buscar equipos por nombre, deporte o categoría...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: _filterTeams,
                ),
                const SizedBox(height: 12),
                // Estadísticas rápidas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                        'Total', _teams.length.toString(), Icons.groups),
                    _buildStatChip(
                        'Fútbol',
                        _teams
                            .where((t) =>
                                t.sport?.toLowerCase().contains('fútbol') ??
                                false)
                            .length
                            .toString(),
                        Icons.sports_soccer),
                    _buildStatChip(
                        'Básquet',
                        _teams
                            .where((t) =>
                                t.sport?.toLowerCase().contains('básquet') ??
                                false)
                            .length
                            .toString(),
                        Icons.sports_basketball),
                    _buildStatChip(
                        'Otros',
                        _teams
                            .where((t) =>
                                !(t.sport?.toLowerCase().contains('fútbol') ??
                                    false) &&
                                !(t.sport?.toLowerCase().contains('básquet') ??
                                    false))
                            .length
                            .toString(),
                        Icons.sports),
                  ],
                ),
              ],
            ),
          ),

          // Lista de equipos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTeams.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = _filteredTeams[index];
                          return _buildTeamCard(team);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTeam,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay equipos registrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron equipos con el término "$_searchQuery".'
                : 'Agrega equipos para comenzar a gestionar tu organización.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addTeam,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Equipo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: () => _editTeam(team),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícono del deporte
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getSportColor(team.sport),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getSportIcon(team.sport),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Información del equipo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (team.sport != null || team.category != null)
                      Row(
                        children: [
                          if (team.sport != null) ...[
                            Icon(
                              Icons.sports,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              team.sport!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (team.sport != null && team.category != null)
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          if (team.category != null) ...[
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              team.category!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (team.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        team.description!,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Acciones
              PopupMenuButton(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editTeam(team);
                      break;
                    case 'delete':
                      _deleteTeam(team);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSportColor(String? sport) {
    if (sport == null) return Colors.grey;
    switch (sport.toLowerCase()) {
      case 'fútbol':
        return Colors.green;
      case 'básquet':
        return Colors.orange;
      case 'vóley':
        return Colors.purple;
      case 'tenis':
        return Colors.blue;
      case 'paddle':
        return Colors.teal;
      case 'hockey':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSportIcon(String? sport) {
    if (sport == null) return Icons.sports;
    switch (sport.toLowerCase()) {
      case 'fútbol':
        return Icons.sports_soccer;
      case 'básquet':
        return Icons.sports_basketball;
      case 'vóley':
        return Icons.sports_volleyball;
      case 'tenis':
        return Icons.sports_tennis;
      case 'paddle':
        return Icons.sports_tennis;
      case 'hockey':
        return Icons.sports_hockey;
      default:
        return Icons.sports;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/player_roster.dart';
import 'package:sportify_amateur/features/sports/roster_form_improved_screen.dart';
import 'package:sportify_amateur/widgets/player_avatar.dart';

class RosterManagementScreen extends StatefulWidget {
  final int? teamId;
  final String? season;

  const RosterManagementScreen({
    super.key,
    this.teamId,
    this.season,
  });

  @override
  State<RosterManagementScreen> createState() => RosterManagementScreenState();
}

class RosterManagementScreenState extends State<RosterManagementScreen> {
  /// Recarga el plantel (p. ej. tras agregar desde el FAB de Gestión Deportiva).
  void reloadRoster() => _loadRoster();
  final RosterService _rosterService = RosterService();
  final TeamService _teamService = TeamService();
  List<PlayerRoster> _roster = [];
  bool _isLoading = true;
  String _selectedSeason = '';
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.season ?? RosterService.getSeasons().first;
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() => _isLoading = true);
    try {
      List<PlayerRoster> roster;
      if (widget.teamId != null) {
        roster = await _rosterService.getRosterByTeam(widget.teamId!,
            season: _selectedSeason);
      } else {
        final teams = await _teamService.getMyTeams();
        if (teams.isEmpty) {
          roster = [];
        } else {
          final seen = <int>{};
          roster = [];
          for (final t in teams) {
            try {
              final chunk = await _rosterService.getRosterByTeam(
                t.teamId,
                season: _selectedSeason,
              );
              for (final row in chunk) {
                if (seen.add(row.id)) {
                  roster.add(row);
                }
              }
            } catch (_) {
              // Omitir equipo si falla (permisos o red)
            }
          }
          roster.sort((a, b) {
            final c = a.teamId.compareTo(b.teamId);
            if (c != 0) return c;
            return a.jerseyNumber.compareTo(b.jerseyNumber);
          });
        }
      }
      setState(() {
        _roster = roster;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading roster: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        String errorMessage = 'Error desconocido al cargar roster';

        if (e
            .toString()
            .contains('type \'Null\' is not a subtype of type \'int\'')) {
          errorMessage =
              'Error de datos: algunos campos requeridos están vacíos en la base de datos';
        } else if (e.toString().contains('FormatException')) {
          errorMessage = 'Error de formato en los datos recibidos del servidor';
        } else if (e.toString().contains('404')) {
          errorMessage = 'No se encontraron datos de roster';
        } else if (e.toString().contains('403')) {
          errorMessage =
              'No tenés permiso para cargar este roster. Probá cerrar sesión y volver a entrar.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<PlayerRoster> get _filteredRoster {
    var filtered = _roster.where((player) {
      // Filtro por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!player.playerName.toLowerCase().contains(query) &&
            !player.jerseyNumber.toString().contains(query) &&
            !player.documentNumber.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtro por estado
      switch (_filterStatus) {
        case 'enabled':
          return player.isEnabled;
        case 'disabled':
          return !player.isEnabled;
        case 'medical_pending':
          return player.medicalStatus == 'pending';
        case 'medical_expired':
          return player.medicalStatus == 'expired' ||
              !player.isMedicalCertificateValid;
        case 'can_play':
          return player.canPlay;
        default:
          return true;
      }
    }).toList();

    // Ordenar por número de camiseta
    filtered.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
    return filtered;
  }

  Future<void> _addPlayer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RosterFormImprovedScreen(
          teamId: widget.teamId,
          season: _selectedSeason,
        ),
      ),
    );
    if (result == true) {
      _loadRoster();
    }
  }

  Future<void> _editPlayer(PlayerRoster player) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RosterFormImprovedScreen(
          roster: player,
          teamId: widget.teamId,
          season: _selectedSeason,
        ),
      ),
    );
    if (result == true) {
      _loadRoster();
    }
  }

  Future<void> _deletePlayer(PlayerRoster player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a "${player.playerName}" '
          'de la lista de buena fe?\n\nEsta acción no se puede deshacer.',
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
        await _rosterService.deleteRoster(player.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${player.playerName} eliminado de la lista'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadRoster();
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
        title: Text(
            widget.teamId != null ? 'Lista de Buena Fe' : 'Gestión de Roster'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPlayer,
            tooltip: 'Agregar Jugador',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoster,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Selector de temporada
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Temporada:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSeason,
                        dropdownColor: Colors.green.shade700,
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items: RosterService.getSeasons().map((season) {
                          return DropdownMenuItem(
                            value: season,
                            child: Text(season),
                          );
                        }).toList(),
                        onChanged: (season) {
                          if (season != null) {
                            setState(() {
                              _selectedSeason = season;
                            });
                            _loadRoster();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barra de búsqueda y filtros
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, número o documento...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.7)),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _filterStatus,
                        dropdownColor: Colors.green.shade700,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        underline: Container(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(
                              value: 'can_play', child: Text('Habilitados')),
                          DropdownMenuItem(
                              value: 'enabled', child: Text('Activos')),
                          DropdownMenuItem(
                              value: 'disabled', child: Text('Inactivos')),
                          DropdownMenuItem(
                              value: 'medical_pending',
                              child: Text('Apto pend.')),
                          DropdownMenuItem(
                              value: 'medical_expired',
                              child: Text('Apto venc.')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Estadísticas rápidas (Wrap evita overflow en pantallas angostas)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStatChip(
                        'Total', _roster.length.toString(), Icons.people),
                    _buildStatChip(
                        'Habilitados',
                        _roster.where((p) => p.canPlay).length.toString(),
                        Icons.check_circle),
                    _buildStatChip(
                        'Pendientes',
                        _roster
                            .where((p) => p.medicalStatus == 'pending')
                            .length
                            .toString(),
                        Icons.pending),
                    _buildStatChip(
                        'Vencidos',
                        _roster
                            .where((p) => !p.isMedicalCertificateValid)
                            .length
                            .toString(),
                        Icons.warning),
                  ],
                ),
              ],
            ),
          ),

          // Lista de jugadores
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRoster.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRoster.length,
                        itemBuilder: (context, index) {
                          final player = _filteredRoster[index];
                          return _buildPlayerCard(player);
                        },
                      ),
          ),
        ],
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
            Icons.sports_soccer,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay jugadores registrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all'
                ? 'No se encontraron jugadores con los filtros aplicados.'
                : 'Agrega jugadores a la lista de buena fe para comenzar.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addPlayer,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Jugador'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerRoster player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: () => _editPlayer(player),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  PlayerAvatar(
                    avatarUrl: player.avatarUrl,
                    displayName: player.playerName,
                    radius: 25,
                    badgeText: player.jerseyNumber.toString(),
                    backgroundColor:
                        player.canPlay ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  // Información del jugador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.playerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              _getPositionIcon(player.position),
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            Text(
                              player.positionDisplayName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.badge,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            Text(
                              player.documentNumber,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Estado y acciones
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(player),
                      const SizedBox(height: 8),
                      PopupMenuButton(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editPlayer(player);
                              break;
                            case 'delete':
                              _deletePlayer(player);
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
                ],
              ),
              // Información adicional del apto médico
              if (player.medicalCertificateExpires != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: player.isMedicalCertificateValid
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        color: player.isMedicalCertificateValid
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Apto médico ${player.isMedicalCertificateValid ? 'válido' : 'vencido'} hasta: ${_formatDate(player.medicalCertificateExpires!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: player.isMedicalCertificateValid
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PlayerRoster player) {
    Color color;
    String text;
    IconData icon;

    if (player.canPlay) {
      color = Colors.green;
      text = 'Habilitado';
      icon = Icons.check_circle;
    } else if (!player.isEnabled) {
      color = Colors.grey;
      text = 'Inactivo';
      icon = Icons.block;
    } else if (player.medicalStatus != 'approved') {
      color = Colors.orange;
      text = player.medicalStatusDisplayName;
      icon = Icons.pending;
    } else if (!player.isMedicalCertificateValid) {
      color = Colors.red;
      text = 'Apto Vencido';
      icon = Icons.warning;
    } else {
      color = Colors.grey;
      text = 'Deshabilitado';
      icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPositionIcon(String position) {
    switch (position) {
      case 'goalkeeper':
        return Icons.sports_handball;
      case 'defender':
        return Icons.shield;
      case 'midfielder':
        return Icons.swap_horiz;
      case 'forward':
        return Icons.sports_soccer;
      default:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

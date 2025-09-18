import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/team.dart';

class TeamAutocomplete extends StatefulWidget {
  final String? initialValue;
  final Function(Team?) onTeamSelected;
  final String? hintText;

  const TeamAutocomplete({
    super.key,
    this.initialValue,
    required this.onTeamSelected,
    this.hintText,
  });

  @override
  State<TeamAutocomplete> createState() => _TeamAutocompleteState();
}

class _TeamAutocompleteState extends State<TeamAutocomplete> {
  final TeamService _teamService = TeamService();
  final TextEditingController _controller = TextEditingController();
  List<Team> _suggestions = [];
  bool _isLoading = false;
  bool _showCreateOption = false;
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  Future<void> _searchTeams(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showCreateOption = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teams = await _teamService.searchTeams(query);
      setState(() {
        _suggestions = teams;
        _showCreateOption = teams.isEmpty ||
            !teams
                .any((team) => team.name.toLowerCase() == query.toLowerCase());
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _showCreateOption = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToCreateTeam(String name) async {
    // Navegar a la pantalla de crear equipo
    final result = await Navigator.pushNamed(
      context,
      '/team-form',
      arguments: {
        'initialName': name,
        'isFromOnboarding': true,
      },
    );

    // Si regresa con un equipo creado
    if (result != null && result is Team) {
      setState(() {
        _selectedTeam = result;
        _controller.text = result.name;
        _suggestions = [];
        _showCreateOption = false;
      });

      widget.onTeamSelected(result);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Equipo "${result.name}" creado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _selectTeam(Team team) {
    setState(() {
      _selectedTeam = team;
      _controller.text = team.name;
      _suggestions = [];
      _showCreateOption = false;
    });
    widget.onTeamSelected(team);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.hintText ?? 'Buscar equipo',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _selectedTeam != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedTeam = null;
                            _controller.clear();
                            _suggestions = [];
                            _showCreateOption = false;
                          });
                          widget.onTeamSelected(null);
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: _searchTeams,
        ),

        // Suggestions list
        if (_suggestions.isNotEmpty || _showCreateOption) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Existing teams
                ..._suggestions.map((team) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          team.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(team.name),
                      subtitle: team.shortInfo.isNotEmpty
                          ? Text(team.shortInfo)
                          : null,
                      onTap: () => _selectTeam(team),
                    )),

                // Create new team option
                if (_showCreateOption && _controller.text.trim().isNotEmpty)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(
                        Icons.add,
                        color: Colors.green[800],
                      ),
                    ),
                    title: Text('Crear "${_controller.text.trim()}"'),
                    subtitle: const Text('Nuevo equipo'),
                    onTap: () => _navigateToCreateTeam(_controller.text.trim()),
                  ),
              ],
            ),
          ),
        ],

        // Selected team display
        if (_selectedTeam != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipo seleccionado: ${_selectedTeam!.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                      if (_selectedTeam!.shortInfo.isNotEmpty)
                        Text(
                          _selectedTeam!.shortInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

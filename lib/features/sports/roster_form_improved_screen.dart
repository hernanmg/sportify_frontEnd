import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/core/services/sport_positions_service.dart';
import 'package:sportify_amateur/models/sport_position.dart';
import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/services/user_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/player_roster.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/models/user.dart';
import 'package:intl/intl.dart';

class RosterFormImprovedScreen extends StatefulWidget {
  final PlayerRoster? roster;
  final int? teamId;
  final String? season;

  const RosterFormImprovedScreen({
    super.key,
    this.roster,
    this.teamId,
    this.season,
  });

  @override
  State<RosterFormImprovedScreen> createState() =>
      _RosterFormImprovedScreenState();
}

class _RosterFormImprovedScreenState extends State<RosterFormImprovedScreen> {
  final _formKey = GlobalKey<FormState>();
  final RosterService _rosterService = RosterService();
  final SportPositionsService _positionsService = SportPositionsService();
  final UserService _userService = UserService();
  final TeamService _teamService = TeamService();

  // Controllers
  final TextEditingController _jerseyNumberController = TextEditingController();
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Form data
  User? _selectedUser;
  Team? _selectedTeam;
  DateTime? _medicalCertificateDate;
  DateTime? _medicalCertificateExpires;
  bool _isEnabled = true;
  String _position = 'player';
  List<SportPosition> _sportPositions = [];
  String _season = '';
  final Set<String> _selectedCategories = {'+35'};
  String _medicalStatus = 'pending';
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Data lists
  List<User> _availableUsers = [];
  List<Team> _availableTeams = [];
  List<int> _availableNumbers = [];
  List<PlayerRoster> _teamRosters = [];
  /// userId → categorías ya fichadas en equipo/temporada actual.
  Map<int, Set<String>> _assignedCategoriesByUserId = {};

  @override
  void initState() {
    super.initState();
    _season = widget.roster?.season ??
        widget.season ??
        RosterService.getSeasons().first;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      List<Team> teams = [];
      try {
        final mine = await _teamService.getMyTeams();
        if (mine.isNotEmpty) {
          teams = mine.map((o) => o.team).toList();
        } else {
          teams = await _teamService.getAllTeams();
        }
      } catch (e) {
        print('Error cargando equipos: $e');
      }

      _availableTeams = teams;

      if (_availableTeams.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No tenés equipos asignados. Unite con un código o completá el onboarding.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (widget.roster != null) {
        try {
          _selectedTeam = _availableTeams.firstWhere(
            (team) => team.id == widget.roster!.teamId,
          );
        } catch (_) {
          _selectedTeam =
              _availableTeams.isNotEmpty ? _availableTeams.first : null;
        }
      } else if (widget.teamId != null && _availableTeams.isNotEmpty) {
        try {
          _selectedTeam = _availableTeams.firstWhere(
            (team) => team.id == widget.teamId,
          );
        } catch (_) {
          _selectedTeam = _availableTeams.first;
        }
      } else if (_availableTeams.length == 1) {
        _selectedTeam = _availableTeams.first;
      }

      if (_selectedTeam != null) {
        await _refreshTeamContext();
      } else {
        _availableUsers = [];
        _teamRosters = [];
        _availableNumbers = [];
      }

      if (widget.roster != null) {
        _applyExistingRosterData();
      }

      if (_selectedTeam != null &&
          _availableUsers.isEmpty &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay personas vinculadas a este equipo en el sistema. Revisá fichajes o membresía.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Recarga usuarios del equipo, nombres de camiseta y roster (misma temporada).
  Future<void> _refreshTeamContext() async {
    final team = _selectedTeam;
    if (team == null) {
      setState(() {
        _availableUsers = [];
        _teamRosters = [];
        _availableNumbers = [];
      });
      return;
    }

    try {
      final sportId = team.sportId;
      if (sportId != null) {
        _sportPositions = await _positionsService.getBySportId(sportId);
        if (!_sportPositions.any((p) => p.code == _position)) {
          _position = _sportPositions.first.code;
        }
      } else {
        _sportPositions = [];
      }

      List<User> users = [];
      try {
        users = await _userService.findForTeam(team.id);
      } catch (e) {
        print('Usuarios por equipo no disponibles: $e');
      }

      List<PlayerRoster> rosters = [];
      try {
        rosters = await _rosterService.getRosterByTeam(
          team.id,
          season: _season,
        );
      } catch (_) {
        rosters = [];
      }

      List<int> numbers = [];
      try {
        numbers = await _rosterService.getAvailableJerseyNumbers(
          team.id,
          _season,
        );
      } catch (e) {
        print('Error loading available numbers: $e');
      }

      final byUser = <int, Set<String>>{};
      for (final row in rosters) {
        final uid = row.player?.userId;
        if (uid == null) continue;
        byUser.putIfAbsent(uid, () => {}).add(row.category);
      }

      if (!mounted) return;
      setState(() {
        _availableUsers = users;
        _teamRosters = rosters;
        _availableNumbers = numbers;
        _assignedCategoriesByUserId = byUser;
        if (widget.roster == null &&
            _selectedUser != null &&
            !_eligibleUsersForPicker().any((u) => u.id == _selectedUser!.id)) {
          _selectedUser = null;
        }
      });
    } catch (e, st) {
      debugPrint('_refreshTeamContext: $e\n$st');
      if (mounted) {
        setState(() {
          _availableUsers = [];
          _teamRosters = [];
          _availableNumbers = [];
        });
      }
    }
  }

  User _stubUserFromRoster(PlayerRoster roster) {
    final p = roster.player;
    final now = DateTime.now();
    final uid = p?.userId ?? roster.playerId;
    return User(
      id: uid,
      name: p?.name ?? 'Jugador ${roster.playerId}',
      email: p?.email ?? '',
      roles: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  void _applyExistingRosterData() {
    final roster = widget.roster!;

    try {
      _selectedTeam = _availableTeams.firstWhere(
        (team) => team.id == roster.teamId,
        orElse: () => _availableTeams.first,
      );
    } catch (_) {}

    final uid = roster.player?.userId;
    if (uid != null) {
      try {
        _selectedUser =
            _availableUsers.firstWhere((user) => user.id == uid);
      } catch (_) {
        final stub = _stubUserFromRoster(roster);
        _availableUsers = [..._availableUsers, stub];
        _selectedUser = stub;
      }
    }

    _jerseyNumberController.text = roster.jerseyNumber.toString();
    _documentNumberController.text = roster.documentNumber;
    _emergencyContactController.text = roster.emergencyContact ?? '';
    _notesController.text = roster.notes ?? '';

    _medicalCertificateDate = roster.medicalCertificateDate;
    _medicalCertificateExpires = roster.medicalCertificateExpires;
    _isEnabled = roster.isEnabled;
    _position = roster.position;
    _season = roster.season;
    _selectedCategories
      ..clear()
      ..add(roster.category);
    _medicalStatus = roster.medicalStatus;
  }

  Future<void> _loadTeamRosters() async {
    if (_selectedTeam == null) return;
    try {
      _teamRosters = await _rosterService.getRosterByTeam(
        _selectedTeam!.id,
        season: _season,
      );
      final byUser = <int, Set<String>>{};
      for (final row in _teamRosters) {
        final uid = row.player?.userId;
        if (uid == null) continue;
        byUser.putIfAbsent(uid, () => {}).add(row.category);
      }
      _assignedCategoriesByUserId = byUser;
    } catch (_) {
      _teamRosters = [];
      _assignedCategoriesByUserId = {};
    }
  }

  List<String> get _teamCategoryLabels {
    final team = _selectedTeam;
    if (team == null) return [];
    if (team.categoryNames.isNotEmpty) return team.categoryNames;
    final fromRoster =
        _teamRosters.map((r) => r.category).where((c) => c.isNotEmpty).toSet();
    if (fromRoster.isNotEmpty) return fromRoster.toList();
    return [];
  }

  List<String> get _selectableCategoryLabels {
    final fromTeam = _teamCategoryLabels;
    if (fromTeam.isNotEmpty) return fromTeam;
    return RosterService.getCategories();
  }

  Set<String> _assignedCategoriesFor(int userId) =>
      _assignedCategoriesByUserId[userId] ?? {};

  bool _isFullyAssigned(int userId) {
    final assigned = _assignedCategoriesFor(userId);
    if (assigned.isEmpty) return false;
    final labels = _teamCategoryLabels;
    if (labels.isNotEmpty) {
      return labels.every(assigned.contains);
    }
    return _selectableCategoryLabels.every(assigned.contains);
  }

  List<String> _missingCategoriesFor(int userId) {
    final assigned = _assignedCategoriesFor(userId);
    final labels = _selectableCategoryLabels;
    return labels.where((c) => !assigned.contains(c)).toList();
  }

  List<User> _eligibleUsersForPicker() {
    if (widget.roster != null) return _availableUsers;
    return _availableUsers
        .where((u) => !_isFullyAssigned(u.id))
        .toList();
  }

  String? _userPickerSubtitle(User user) {
    final assigned = _assignedCategoriesFor(user.id);
    if (assigned.isEmpty) return null;
    return 'Ya fichado en: ${assigned.join(', ')}';
  }

  void _prefillFromSelectedUser() {
    if (_selectedUser == null) return;
    final uid = _selectedUser!.id;
    final matches =
        _teamRosters.where((r) => r.player?.userId == uid).toList();
    if (matches.isEmpty) {
      if (widget.roster == null) {
        final missing = _missingCategoriesFor(uid);
        if (missing.isNotEmpty) {
          setState(() {
            _selectedCategories
              ..clear()
              ..addAll(missing);
          });
        }
      }
      return;
    }

    final first = matches.first;
    if (_documentNumberController.text.isEmpty) {
      _documentNumberController.text = first.documentNumber;
    }
    if (_emergencyContactController.text.isEmpty &&
        first.emergencyContact != null) {
      _emergencyContactController.text = first.emergencyContact!;
    }
    if (_jerseyNumberController.text.isEmpty) {
      _jerseyNumberController.text = first.jerseyNumber.toString();
    }
    if (widget.roster == null) {
      final missing = _missingCategoriesFor(uid);
      setState(() {
        _selectedCategories
          ..clear()
          ..addAll(missing.isNotEmpty ? missing : [first.category]);
      });
    } else {
      _selectedCategories
        ..clear()
        ..add(first.category);
    }
    _position = first.position;
    _medicalStatus = first.medicalStatus;
  }

  Future<void> _loadAvailableNumbers() async {
    if (_selectedTeam != null) {
      try {
        final numbers = await _rosterService.getAvailableJerseyNumbers(
          _selectedTeam!.id,
          _season,
        );
        setState(() {
          _availableNumbers = numbers;
        });
      } catch (e) {
        print('Error loading available numbers: $e');
      }
    }
  }

  @override
  void dispose() {
    _jerseyNumberController.dispose();
    _documentNumberController.dispose();
    _emergencyContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isExpiration) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiration
          ? (_medicalCertificateExpires ??
              DateTime.now().add(const Duration(days: 365)))
          : (_medicalCertificateDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isExpiration) {
          _medicalCertificateExpires = picked;
        } else {
          _medicalCertificateDate = picked;
        }
      });
    }
  }

  Future<void> _saveRoster() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un equipo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná al menos una categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseData = {
        'playerId': _selectedUser!.id,
        'teamId': _selectedTeam!.id,
        'jerseyNumber': int.parse(_jerseyNumberController.text),
        'medicalCertificateDate': _medicalCertificateDate?.toIso8601String(),
        'medicalCertificateExpires':
            _medicalCertificateExpires?.toIso8601String(),
        'isEnabled': _isEnabled,
        'position': _position,
        'documentNumber': _documentNumberController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        'season': _season,
        'medicalStatus': _medicalStatus,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (widget.roster == null) {
        final assigned = _assignedCategoriesFor(_selectedUser!.id);
        final toCreate = _selectedCategories
            .where((c) => !assigned.contains(c))
            .toList();
        if (toCreate.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  assigned.isEmpty
                      ? 'Seleccioná al menos una categoría nueva'
                      : '${_selectedUser!.name} ya está en ${assigned.join(', ')}. Elegí otra categoría.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        var created = 0;
        for (final category in toCreate) {
          try {
            await _rosterService.createRoster({
              ...baseData,
              'category': category,
            });
            created++;
          } catch (e) {
            final msg = e.toString();
            if (!msg.contains('ya está registrado')) rethrow;
          }
        }
        if (created == 0) {
          throw Exception(
            'El jugador ya está en todas las categorías seleccionadas',
          );
        }
      } else {
        final assigned = _assignedCategoriesFor(_selectedUser!.id);
        final currentCategory = widget.roster!.category;
        var updatedCurrent = false;

        if (_selectedCategories.contains(currentCategory)) {
          await _rosterService.updateRoster(widget.roster!.id, {
            ...baseData,
            'category': currentCategory,
          });
          updatedCurrent = true;
        } else if (_selectedCategories.isNotEmpty) {
          await _rosterService.updateRoster(widget.roster!.id, {
            ...baseData,
            'category': _selectedCategories.first,
          });
          updatedCurrent = true;
        }

        var created = 0;
        for (final category in _selectedCategories) {
          if (assigned.contains(category)) continue;
          try {
            await _rosterService.createRoster({
              ...baseData,
              'category': category,
            });
            created++;
          } catch (e) {
            final msg = e.toString();
            if (!msg.contains('ya está registrado')) rethrow;
          }
        }

        if (!updatedCurrent && created == 0) {
          throw Exception(
            'Seleccioná al menos una categoría (actual o nueva)',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.roster == null
                  ? '${_selectedUser!.name} agregado a la lista de buena fe'
                  : 'Información de ${_selectedUser!.name} actualizada',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMessage = 'Error desconocido';

        final errorString = e is DioException
            ? RosterService.errorMessage(e)
            : e.toString();
        if (errorString.contains('Usuario con ID') &&
            errorString.contains('no encontrado')) {
          errorMessage = 'El usuario seleccionado no existe en el sistema';
        } else if (errorString.contains('Equipo con ID') &&
            errorString.contains('no encontrado')) {
          errorMessage = 'El equipo seleccionado no existe';
        } else if (errorString.contains('número') &&
            errorString.contains('ocupado')) {
          errorMessage =
              'El número de camiseta ya está ocupado en esta temporada';
        } else if (errorString.contains('ya está registrado')) {
          errorMessage =
              'El jugador ya está registrado en esta temporada para este equipo';
        } else if (errorString.contains('404')) {
          errorMessage =
              'Recurso no encontrado. Verifica que el usuario y equipo existan.';
        } else if (errorString.contains('403')) {
          errorMessage = 'No tienes permisos para realizar esta acción';
        } else if (errorString.contains('400')) {
          errorMessage = 'Datos inválidos. Verifica la información ingresada.';
        } else if (errorString.contains('500')) {
          errorMessage = 'Error interno del servidor. Intenta nuevamente.';
        } else {
          // Limpiar el mensaje de error
          errorMessage = errorString
              .replaceFirst('Exception: ', '')
              .replaceFirst('Error de conexión: ', '')
              .replaceAll('DioException', 'Error de conexión')
              .replaceAll('Client error', 'Error del cliente');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando usuarios y equipos...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.roster == null ? 'Agregar Jugador' : 'Editar Jugador'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Equipo y Temporada'),
              _buildTeamSelector(),
              const SizedBox(height: 16),
              _buildSeasonSelector(),
              const SizedBox(height: 24),

              _buildSectionTitle('Seleccionar Jugador'),
              _buildUserSelector(),
              const SizedBox(height: 24),

              // Información del jugador
              _buildSectionTitle('Información del Jugador'),
              _buildPlayerInfo(),
              const SizedBox(height: 24),

              // Apto médico
              _buildSectionTitle('Apto Médico'),
              _buildMedicalInfo(),
              const SizedBox(height: 24),

              // Información adicional
              _buildSectionTitle('Información Adicional'),
              _buildAdditionalInfo(),
              const SizedBox(height: 32),

              // Botón guardar
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  /// Dos campos en fila en pantallas anchas; en columna en móvil/emulador.
  Widget _responsiveFieldRow(List<Widget> fields, {double breakpoint = 520}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                fields[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: fields[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUserSelector() {
    final pickerUsers = _eligibleUsersForPicker();
    final assignedSelected = _selectedUser != null
        ? _assignedCategoriesFor(_selectedUser!.id)
        : <String>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Usuario del Sistema',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedTeam != null &&
              _availableUsers.isNotEmpty &&
              pickerUsers.isEmpty &&
              widget.roster == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Todos los integrantes del equipo ya están fichados en todas las categorías de esta temporada.',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
              ),
            ),
          DropdownButtonFormField<User>(
            value: _selectedUser != null &&
                    pickerUsers.any((u) => u.id == _selectedUser!.id)
                ? _selectedUser
                : null,
            decoration: InputDecoration(
              labelText: 'Seleccionar Usuario',
              border: const OutlineInputBorder(),
              helperText: _selectedTeam == null
                  ? 'Elegí un equipo arriba para ver a quién podés fichar'
                  : widget.roster == null
                      ? 'Solo quienes faltan fichar en al menos una categoría'
                      : 'Personas vinculadas a este equipo',
            ),
            isExpanded: true,
            itemHeight: pickerUsers.any((u) => _userPickerSubtitle(u) != null)
                ? 64
                : kMinInteractiveDimension,
            selectedItemBuilder: (context) {
              return pickerUsers.map((user) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList();
            },
            items: pickerUsers.map((user) {
              final subtitle = _userPickerSubtitle(user);
              final title = user.email.isNotEmpty
                  ? '${user.name} (${user.email})'
                  : user.name;
              return DropdownMenuItem(
                value: user,
                child: Text(
                  subtitle != null ? '$title\n$subtitle' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, height: 1.25),
                ),
              );
            }).toList(),
            onChanged: (_selectedTeam == null || pickerUsers.isEmpty)
                ? null
                : (user) {
                    setState(() {
                      _selectedUser = user;
                    });
                    _prefillFromSelectedUser();
                  },
            validator: (value) {
              if (value == null) {
                return 'Debes seleccionar un usuario';
              }
              return null;
            },
          ),
          if (assignedSelected.isNotEmpty && widget.roster == null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Ya está en: ${assignedSelected.join(', ')}. '
                'Solo podés agregar categorías que aún no tenga.',
                style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSelector() {
    return DropdownButtonFormField<Team>(
      value: _selectedTeam,
      decoration: const InputDecoration(
        labelText: 'Equipo',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.groups),
      ),
      isExpanded: true,
      items: _availableTeams.map((team) {
        return DropdownMenuItem(
          value: team,
          child: Text(team.name),
        );
      }).toList(),
      onChanged: widget.teamId == null
          ? (team) async {
              setState(() {
                _selectedTeam = team;
                _selectedUser = null;
              });
              await _refreshTeamContext();
            }
          : null,
      validator: (value) {
        if (value == null) {
          return 'Debes seleccionar un equipo';
        }
        return null;
      },
    );
  }

  Widget _buildSeasonSelector() {
    final seasonDropdown = DropdownButtonFormField<String>(
      value: _season,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Temporada',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
      ),
      items: RosterService.getSeasons().map((season) {
        return DropdownMenuItem(
          value: season,
          child: Text(
            season,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) async {
        if (value != null) {
          setState(() {
            _season = value;
          });
          await _loadTeamRosters();
          await _loadAvailableNumbers();
          if (mounted) {
            setState(() {});
            _prefillFromSelectedUser();
          }
        }
      },
    );

    final categoriesBlock = InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Categorías',
        border: OutlineInputBorder(),
        helperText: 'Podés elegir varias (+35, +40, etc.)',
      ),
      child: Wrap(
        spacing: 8,
        children: _selectableCategoryLabels.map((category) {
          final selected = _selectedCategories.contains(category);
          final assigned = _assignedCategoriesFor(_selectedUser?.id ?? -1);
          final isCurrentRowCategory = widget.roster?.category == category;
          final lockedElsewhere = _selectedUser != null &&
              assigned.contains(category) &&
              !isCurrentRowCategory;
          return FilterChip(
            label: Text(
              lockedElsewhere
                  ? '$category (ya fichado)'
                  : isCurrentRowCategory
                      ? '$category (actual)'
                      : category,
            ),
            selected: selected,
            onSelected: lockedElsewhere
                ? null
                : (v) {
                    setState(() {
                      if (v) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
          );
        }).toList(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              seasonDropdown,
              const SizedBox(height: 12),
              categoriesBlock,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: seasonDropdown),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: categoriesBlock),
          ],
        );
      },
    );
  }

  Widget _buildPlayerInfo() {
    return Column(
      children: [
        _responsiveFieldRow([
          TextFormField(
            controller: _jerseyNumberController,
            decoration: InputDecoration(
              labelText: 'Número de Camiseta',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.sports_soccer),
              helperText: _availableNumbers.isNotEmpty
                  ? 'Disp.: ${_availableNumbers.take(8).join(', ')}${_availableNumbers.length > 8 ? '…' : ''}'
                  : null,
              helperMaxLines: 2,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El número de camiseta es requerido';
              }
              final number = int.tryParse(value);
              if (number == null || number < 1 || number > 99) {
                return 'Debe ser un número entre 1 y 99';
              }
              return null;
            },
          ),
          DropdownButtonFormField<String>(
            value: _position,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Posición',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.sports),
            ),
            items: (_sportPositions.isNotEmpty
                    ? _sportPositions
                    : [
                        SportPosition(
                          id: 0,
                          sportId: 0,
                          code: 'player',
                          label: 'Jugador',
                        ),
                      ])
                .map((pos) {
              return DropdownMenuItem(
                value: pos.code,
                child: Text(
                  pos.label,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              final list = _sportPositions.isNotEmpty
                  ? _sportPositions
                  : [
                      SportPosition(
                        id: 0,
                        sportId: 0,
                        code: 'player',
                        label: 'Jugador',
                      ),
                    ];
              return list.map((pos) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    pos.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList();
            },
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _position = value;
                });
              }
            },
          ),
        ]),
        const SizedBox(height: 16),
        TextFormField(
          controller: _documentNumberController,
          decoration: const InputDecoration(
            labelText: 'Número de Documento',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
            helperText: 'DNI, CI, Pasaporte, etc.',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El número de documento es requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMedicalInfo() {
    return Column(
      children: [
        _responsiveFieldRow([
          InkWell(
            onTap: () => _selectDate(context, false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha del Apto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              child: Text(
                _medicalCertificateDate != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(_medicalCertificateDate!)
                    : 'Seleccionar fecha',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          InkWell(
            onTap: () => _selectDate(context, true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de Vencimiento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_busy),
              ),
              child: Text(
                _medicalCertificateExpires != null
                    ? DateFormat('dd/MM/yyyy')
                        .format(_medicalCertificateExpires!)
                    : 'Seleccionar fecha',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _medicalStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado del Apto Médico',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.health_and_safety),
          ),
          items: RosterService.getMedicalStatuses().map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                RosterService.getMedicalStatusDisplayName(status),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _medicalStatus = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        TextFormField(
          controller: _emergencyContactController,
          decoration: const InputDecoration(
            labelText: 'Contacto de Emergencia (Opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.emergency),
            helperText: 'Nombre y teléfono de contacto',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notas (Opcional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
            helperText: 'Observaciones adicionales',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Jugador Habilitado'),
          subtitle: const Text('Puede participar en eventos del equipo'),
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          },
          activeColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveRoster,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save, color: Colors.white),
        label: Text(
          widget.roster == null
              ? 'Agregar a Lista de Buena Fe'
              : 'Guardar Cambios',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

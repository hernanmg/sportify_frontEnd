import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
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
  String _season = '';
  String _category = '+35';
  String _medicalStatus = 'pending';
  bool _isLoading = false;
  bool _isLoadingData = true;

  // Data lists
  List<User> _availableUsers = [];
  List<Team> _availableTeams = [];
  List<int> _availableNumbers = [];

  @override
  void initState() {
    super.initState();
    _season = widget.season ?? RosterService.getSeasons().first;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);

    try {
      // Cargar usuarios y equipos en paralelo
      final futures = await Future.wait([
        _userService.findAll(),
        _teamService.getAllTeams(),
      ]);

      _availableUsers = futures[0] as List<User>;
      _availableTeams = futures[1] as List<Team>;

      // Si se pasa un teamId, pre-seleccionar el equipo
      if (widget.teamId != null) {
        _selectedTeam = _availableTeams.firstWhere(
          (team) => team.id == widget.teamId,
          orElse: () => _availableTeams.first,
        );
        await _loadAvailableNumbers();
      }

      // Si es edición, cargar datos existentes
      if (widget.roster != null) {
        _loadExistingData();
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

  void _loadExistingData() {
    final roster = widget.roster!;

    // Buscar el usuario correspondiente
    _selectedUser = _availableUsers.firstWhere(
      (user) => user.id == roster.playerId,
      orElse: () => _availableUsers.first,
    );

    // Buscar el equipo correspondiente
    _selectedTeam = _availableTeams.firstWhere(
      (team) => team.id == roster.teamId,
      orElse: () => _availableTeams.first,
    );

    _jerseyNumberController.text = roster.jerseyNumber.toString();
    _documentNumberController.text = roster.documentNumber;
    _emergencyContactController.text = roster.emergencyContact ?? '';
    _notesController.text = roster.notes ?? '';

    _medicalCertificateDate = roster.medicalCertificateDate;
    _medicalCertificateExpires = roster.medicalCertificateExpires;
    _isEnabled = roster.isEnabled;
    _position = roster.position;
    _season = roster.season;
    _category = roster.category;
    _medicalStatus = roster.medicalStatus;
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

    setState(() => _isLoading = true);

    try {
      final rosterData = {
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
        'category': _category,
        'medicalStatus': _medicalStatus,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      if (widget.roster == null) {
        await _rosterService.createRoster(rosterData);
      } else {
        await _rosterService.updateRoster(widget.roster!.id, rosterData);
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

        // Extraer mensaje de error más específico
        final errorString = e.toString();
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
              // Selección de Usuario
              _buildSectionTitle('Seleccionar Jugador'),
              _buildUserSelector(),
              const SizedBox(height: 24),

              // Selección de Equipo
              _buildSectionTitle('Equipo y Temporada'),
              _buildTeamSelector(),
              const SizedBox(height: 16),
              _buildSeasonSelector(),
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

  Widget _buildUserSelector() {
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
              Text(
                'Usuario del Sistema',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<User>(
            value: _selectedUser,
            decoration: const InputDecoration(
              labelText: 'Seleccionar Usuario',
              border: OutlineInputBorder(),
              helperText: 'Usuario registrado en el sistema',
            ),
            isExpanded: true,
            items: _availableUsers.map((user) {
              return DropdownMenuItem(
                value: user,
                child: Text(
                  user.email.isNotEmpty
                      ? '${user.name} (${user.email})'
                      : user.name,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (user) {
              setState(() {
                _selectedUser = user;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Debes seleccionar un usuario';
              }
              return null;
            },
          ),
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
          ? (team) {
              setState(() {
                _selectedTeam = team;
              });
              _loadAvailableNumbers();
            }
          : null, // Deshabilitar si teamId está fijo
      validator: (value) {
        if (value == null) {
          return 'Debes seleccionar un equipo';
        }
        return null;
      },
    );
  }

  Widget _buildSeasonSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _season,
            decoration: const InputDecoration(
              labelText: 'Temporada',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: RosterService.getSeasons().map((season) {
              return DropdownMenuItem(
                value: season,
                child: Text(season),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _season = value;
                });
                _loadAvailableNumbers();
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: RosterService.getCategories().map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _category = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _jerseyNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de Camiseta',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.sports_soccer),
                  helperText: _availableNumbers.isNotEmpty
                      ? 'Disponibles: ${_availableNumbers.take(10).join(', ')}${_availableNumbers.length > 10 ? '...' : ''}'
                      : null,
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _position,
                decoration: const InputDecoration(
                  labelText: 'Posición',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports),
                ),
                items: RosterService.getPositions().map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(RosterService.getPositionDisplayName(position)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _position = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
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
        Row(
          children: [
            Expanded(
              child: InkWell(
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
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
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
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _medicalStatus,
          decoration: const InputDecoration(
            labelText: 'Estado del Apto Médico',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.health_and_safety),
          ),
          items: RosterService.getMedicalStatuses().map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(RosterService.getMedicalStatusDisplayName(status)),
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

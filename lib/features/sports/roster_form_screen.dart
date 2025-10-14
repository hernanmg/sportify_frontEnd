import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/models/player_roster.dart';
import 'package:intl/intl.dart';

class RosterFormScreen extends StatefulWidget {
  final PlayerRoster? roster;
  final int? teamId;
  final String? season;

  const RosterFormScreen({
    super.key,
    this.roster,
    this.teamId,
    this.season,
  });

  @override
  State<RosterFormScreen> createState() => _RosterFormScreenState();
}

class _RosterFormScreenState extends State<RosterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RosterService _rosterService = RosterService();

  // Controllers
  final TextEditingController _playerIdController = TextEditingController();
  final TextEditingController _teamIdController = TextEditingController();
  final TextEditingController _jerseyNumberController = TextEditingController();
  final TextEditingController _documentNumberController =
      TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Form data
  DateTime? _medicalCertificateDate;
  DateTime? _medicalCertificateExpires;
  bool _isEnabled = true;
  String _position = 'player';
  String _season = '';
  String _category = '+35';
  String _medicalStatus = 'pending';
  bool _isLoading = false;
  List<int> _availableNumbers = [];

  @override
  void initState() {
    super.initState();
    _season = widget.season ?? RosterService.getSeasons().first;

    if (widget.roster != null) {
      _loadExistingData();
    } else {
      _teamIdController.text = widget.teamId?.toString() ?? '';
      _loadAvailableNumbers();
    }
  }

  void _loadExistingData() {
    final roster = widget.roster!;
    _playerIdController.text = roster.playerId.toString();
    _teamIdController.text = roster.teamId.toString();
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
    if (widget.teamId != null) {
      try {
        final numbers = await _rosterService.getAvailableJerseyNumbers(
          widget.teamId!,
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
    _playerIdController.dispose();
    _teamIdController.dispose();
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

    setState(() => _isLoading = true);

    try {
      final rosterData = {
        'playerId': int.parse(_playerIdController.text),
        'teamId': int.parse(_teamIdController.text),
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
                  ? 'Jugador agregado a la lista de buena fe'
                  : 'Información del jugador actualizada',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Información básica
              _buildSectionTitle('Información Básica'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _playerIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID del Jugador',
                        border: OutlineInputBorder(),
                        helperText: 'ID del jugador en el sistema',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El ID del jugador es requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _teamIdController,
                      decoration: const InputDecoration(
                        labelText: 'ID del Equipo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      enabled: widget.teamId ==
                          null, // Solo editable si no se pasa teamId
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El ID del equipo es requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Número de camiseta
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _jerseyNumberController,
                      decoration: InputDecoration(
                        labelText: 'Número de Camiseta',
                        border: const OutlineInputBorder(),
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
                      ),
                      items: RosterService.getPositions().map((position) {
                        return DropdownMenuItem(
                          value: position,
                          child: Text(
                              RosterService.getPositionDisplayName(position)),
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

              // Documento
              TextFormField(
                controller: _documentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento',
                  border: OutlineInputBorder(),
                  helperText: 'DNI, CI, Pasaporte, etc.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El número de documento es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Temporada y categoría
              _buildSectionTitle('Temporada y Categoría'),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _season,
                      decoration: const InputDecoration(
                        labelText: 'Temporada',
                        border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 24),

              // Apto médico
              _buildSectionTitle('Apto Médico'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha del Apto',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
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
                          suffixIcon: Icon(Icons.calendar_today),
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
                ),
                items: RosterService.getMedicalStatuses().map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child:
                        Text(RosterService.getMedicalStatusDisplayName(status)),
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
              const SizedBox(height: 24),

              // Contacto de emergencia
              _buildSectionTitle('Información Adicional'),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Contacto de Emergencia (Opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Nombre y teléfono de contacto',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (Opcional)',
                  border: OutlineInputBorder(),
                  helperText: 'Observaciones adicionales',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Estado habilitado
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
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
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
                        ? 'Agregar Jugador'
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
              ),
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
}

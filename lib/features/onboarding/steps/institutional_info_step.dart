import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/onboarding/widgets/team_autocomplete.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/models/role.dart';
import 'package:sportify_amateur/core/services/role_service.dart';

class InstitutionalInfoStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSkip;

  const InstitutionalInfoStep({
    super.key,
    required this.initialData,
    required this.onNext,
    required this.onPrevious,
    required this.onSkip,
  });

  @override
  State<InstitutionalInfoStep> createState() => _InstitutionalInfoStepState();
}

class _InstitutionalInfoStepState extends State<InstitutionalInfoStep> {
  bool _hasTeam = false;
  String _selectedRole = 'player'; // Valor por defecto
  Team? _selectedTeam;
  List<Role> _availableRoles = [];
  bool _loadingRoles = true;
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _hasTeam = widget.initialData['hasTeam'] ?? false;
    _selectedRole = widget.initialData['role'] ?? 'player';
    if (widget.initialData['selectedTeam'] != null) {
      _selectedTeam = Team.fromJson(widget.initialData['selectedTeam']);
    }
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      // Cargar solo roles de equipo para el onboarding
      final roles = await _roleService.getTeamRoles();
      setState(() {
        _availableRoles = roles;
        _loadingRoles = false;
        // Si el rol seleccionado no está en la lista, usar el primero disponible
        if (roles.isNotEmpty && !roles.any((r) => r.name == _selectedRole)) {
          _selectedRole = roles.first.name;
        }
      });
    } catch (e) {
      print('Error cargando roles: $e');
      setState(() {
        _loadingRoles = false;
        // Fallback a roles hardcodeados si falla la carga
        _availableRoles = [
          Role(
            id: 4,
            name: 'player',
            description: 'Jugador activo de un equipo',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Role(
            id: 3,
            name: 'team_captain',
            description: 'Capitán de equipo',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      });
    }
  }

  void _handleNext() {
    // Guardamos los datos institucionales en el wizard
    // Estos datos NO van al backend User, solo se almacenan localmente
    final institutionalData = <String, dynamic>{
      'hasTeam': _hasTeam,
      'role': _selectedRole,
      'selectedTeam': _selectedTeam?.toJson(),
      'teamId': _selectedTeam?.id,
      'teamName': _selectedTeam?.name,
    };

    // Pasamos los datos institucionales
    // El wizard filtrará automáticamente qué campos van al backend
    widget.onNext(institutionalData);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información institucional',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¿Formas parte de algún equipo o club?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ¿Tienes equipo?
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '¿Perteneces a algún equipo?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Sí'),
                                value: true,
                                groupValue: _hasTeam,
                                onChanged: (value) {
                                  setState(() {
                                    _hasTeam = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('No'),
                                value: false,
                                groupValue: _hasTeam,
                                onChanged: (value) {
                                  setState(() {
                                    _hasTeam = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_hasTeam) ...[
                    const SizedBox(height: 20),

                    // Búsqueda/selección de equipo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿A qué equipo perteneces?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TeamAutocomplete(
                            hintText: 'Buscar o crear equipo',
                            onTeamSelected: (team) {
                              setState(() {
                                _selectedTeam = team;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Rol en el equipo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Cuál es tu rol principal?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _loadingRoles
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _selectedRole,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  items: _availableRoles.map((role) {
                                    return DropdownMenuItem(
                                      value: role.name,
                                      child: Text(
                                          RoleService.getRoleDisplayName(
                                              role.name)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                          if (!_loadingRoles && _availableRoles.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                RoleService.getRoleDescription(_selectedRole),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Info sobre equipos múltiples
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Equipos múltiples!',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Podrás unirte a múltiples equipos y cambiar entre ellos fácilmente desde el dashboard.',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: widget.onPrevious,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text('Anterior'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: widget.onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text(
                    'Saltar este paso',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

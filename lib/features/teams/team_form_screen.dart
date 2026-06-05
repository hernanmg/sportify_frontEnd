import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/core/services/category_service.dart';
import 'package:sportify_amateur/core/services/sport_service.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/models/category.dart';
import 'package:sportify_amateur/models/sport.dart';

class TeamFormScreen extends StatefulWidget {
  final Team? team;
  final String? initialName;
  final bool isFromOnboarding;

  const TeamFormScreen({
    super.key,
    this.team,
    this.initialName,
    this.isFromOnboarding = false,
  });

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TeamService _teamService = TeamService();
  final CategoryService _categoryService = CategoryService();
  final SportService _sportService = SportService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _colorsController;
  late TextEditingController _foundedYearController;

  List<Sport> _sports = [];
  Sport? _selectedSport;
  final Set<int> _selectedCategoryIds = {};
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingSports = false;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadSports();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
        text: widget.team?.name ?? widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.team?.description ?? '');
    _colorsController = TextEditingController(text: widget.team?.colors ?? '');
    _foundedYearController =
        TextEditingController(text: widget.team?.foundedYear?.toString() ?? '');
  }

  Future<void> _loadSports() async {
    setState(() => _isLoadingSports = true);
    try {
      final sports = await _sportService.getAllSports();
      Sport? selected;
      if (widget.team?.sportId != null) {
        try {
          selected = sports.firstWhere((s) => s.id == widget.team!.sportId);
        } catch (_) {
          selected = sports.isNotEmpty ? sports.first : null;
        }
      } else {
        selected = sports.isNotEmpty ? sports.first : null;
      }
      setState(() {
        _sports = sports;
        _selectedSport = selected;
      });
      if (selected != null) {
        await _loadCategories();
      }
    } catch (e) {
      _showError('Error al cargar deportes: $e');
    } finally {
      setState(() => _isLoadingSports = false);
    }
  }

  Future<void> _loadCategories() async {
    if (_selectedSport == null) {
      setState(() {
        _categories = [];
        _selectedCategoryIds.clear();
      });
      return;
    }

    setState(() => _isLoadingCategories = true);
    try {
      final categories =
          await _categoryService.getCategoriesBySport(_selectedSport!.id);
      setState(() {
        _categories = categories;
        _selectedCategoryIds.clear();
        if (widget.team != null) {
          if (widget.team!.categoryIds.isNotEmpty) {
            _selectedCategoryIds.addAll(widget.team!.categoryIds);
          } else if (widget.team!.categoryId != null) {
            _selectedCategoryIds.add(widget.team!.categoryId!);
          }
        }
        if (_selectedCategoryIds.isEmpty && categories.isNotEmpty) {
          _selectedCategoryIds.add(categories.first.id);
        }
      });
    } catch (e) {
      _showError('Error al cargar categorías: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSport == null) {
      _showError('Seleccioná un deporte. Si no hay ninguno, cargalos en Gestión de Equipos > Deportes.');
      return;
    }

    if (_selectedCategoryIds.isEmpty) {
      _showError('Seleccioná al menos una categoría para el equipo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teamData = {
        'name': _nameController.text.trim(),
        'sport_id': _selectedSport!.id,
        'category_id': _selectedCategoryIds.first,
        'categoryIds': _selectedCategoryIds.toList(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'founded_year': _foundedYearController.text.trim().isEmpty
            ? null
            : int.parse(_foundedYearController.text.trim()),
        'colors': _colorsController.text.trim().isEmpty
            ? null
            : _colorsController.text.trim(),
      };

      Team savedTeam;
      if (widget.team != null) {
        savedTeam = await _teamService.updateTeam(widget.team!.id, teamData);
        await _teamService.setTeamCategories(
          savedTeam.id,
          _selectedCategoryIds.toList(),
        );
        _showSuccess('Equipo actualizado exitosamente');
      } else {
        savedTeam = await _teamService.createTeam(teamData);
        await _teamService.setTeamCategories(
          savedTeam.id,
          _selectedCategoryIds.toList(),
        );
        _showSuccess(
          'Equipo creado. Ya quedaste asignado como encargado del club.',
        );
      }

      if (widget.isFromOnboarding) {
        // Regresar al onboarding con el equipo creado
        Navigator.pop(context, savedTeam);
      } else {
        // Navegación normal
        Navigator.pop(context, savedTeam);
      }
    } catch (e) {
      _showError('Error al guardar equipo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isFromOnboarding =
        args?['isFromOnboarding'] ?? widget.isFromOnboarding;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.team == null ? 'Crear Equipo' : 'Editar Equipo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading || _isLoadingSports
          ? const Center(child: CircularProgressIndicator())
          : _sports.isEmpty
              ? _buildNoSportsState()
              : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
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
                                Text(
                                  widget.team == null
                                      ? 'Nuevo Equipo'
                                      : 'Editar Equipo',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isFromOnboarding
                                      ? 'Completa los datos para crear tu equipo'
                                      : 'Configura la información del equipo',
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

                    // Nombre del equipo
                    _buildTextFormField(
                      controller: _nameController,
                      label: 'Nombre del equipo *',
                      icon: Icons.sports_soccer,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'El nombre es requerido';
                        }
                        if (value!.length < 2) {
                          return 'El nombre debe tener al menos 2 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildSportDropdown(),

                    const SizedBox(height: 20),

                    // Categoría
                    _buildCategoryDropdown(),

                    const SizedBox(height: 20),

                    // Descripción
                    _buildTextFormField(
                      controller: _descriptionController,
                      label: 'Descripción (opcional)',
                      icon: Icons.description,
                      maxLines: 3,
                      hintText: 'Cuenta algo sobre tu equipo...',
                    ),

                    const SizedBox(height: 20),

                    // Año de fundación y colores
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            controller: _foundedYearController,
                            label: 'Año fundación',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final year = int.tryParse(value);
                                if (year == null ||
                                    year < 1800 ||
                                    year > DateTime.now().year) {
                                  return 'Año inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextFormField(
                            controller: _colorsController,
                            label: 'Colores',
                            icon: Icons.palette,
                            hintText: 'Ej: Azul y amarillo',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _saveTeam,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.team == null
                                  ? 'Crear Equipo'
                                  : 'Guardar Cambios',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildNoSportsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay deportes cargados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Andá a Gestión de Equipos > Deportes y cargá los iniciales antes de crear un equipo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deporte *',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<Sport>(
            value: _selectedSport,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.sports, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: _sports
                .map(
                  (sport) => DropdownMenuItem(
                    value: sport,
                    child: Text(sport.name),
                  ),
                )
                .toList(),
            onChanged: (sport) {
              setState(() {
                _selectedSport = sport;
                _selectedCategoryIds.clear();
              });
              _loadCategories();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías del equipo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Un solo equipo (ej. ZFC) puede jugar +35 y +40',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.white,
          ),
          child: _isLoadingCategories
              ? const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Cargando categorías...'),
                  ],
                )
              : _categories.isEmpty
                  ? const Text(
                      'No hay categorías para este deporte. Cargalas en Gestión de Equipos > Categorías.',
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final selected =
                            _selectedCategoryIds.contains(category.id);
                        return FilterChip(
                          label: Text(category.displayName),
                          selected: selected,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedCategoryIds.add(category.id);
                              } else {
                                _selectedCategoryIds.remove(category.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorsController.dispose();
    _foundedYearController.dispose();
    super.dispose();
  }
}

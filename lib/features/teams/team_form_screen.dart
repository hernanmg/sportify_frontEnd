import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/core/services/category_service.dart';
import 'package:sportify_amateur/models/team.dart';
import 'package:sportify_amateur/models/category.dart';

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

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _colorsController;
  late TextEditingController _foundedYearController;

  int _selectedSportId = 1; // Por defecto Fútbol
  Category? _selectedCategory;
  List<Category> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadCategories();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
        text: widget.team?.name ?? widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.team?.description ?? '');
    _colorsController = TextEditingController(text: widget.team?.colors ?? '');
    _foundedYearController =
        TextEditingController(text: widget.team?.foundedYear?.toString() ?? '');

    if (widget.team != null) {
      _selectedSportId =
          widget.team!.sportId ?? 1; // Default a Fútbol si es null
      // TODO: Cargar categoría del equipo existente
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories =
          await _categoryService.getCategoriesBySport(_selectedSportId);
      setState(() {
        _categories = categories;
        // Si el equipo tiene categoría, seleccionarla
        if (widget.team?.categoryId != null) {
          _selectedCategory = categories.firstWhere(
            (cat) => cat.id == widget.team!.categoryId,
            orElse: () => categories.first,
          );
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

    setState(() => _isLoading = true);

    try {
      final teamData = {
        'name': _nameController.text.trim(),
        'sport_id': _selectedSportId,
        'category_id': _selectedCategory?.id,
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
        // Actualizar equipo existente
        savedTeam = await _teamService.updateTeam(widget.team!.id, teamData);
        _showSuccess('Equipo actualizado exitosamente');
      } else {
        // Crear nuevo equipo
        savedTeam = await _teamService.createTeam(teamData);
        _showSuccess('Equipo creado exitosamente');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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

                    // Deporte (por ahora solo Fútbol)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sports_soccer, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          const Text(
                            'Deporte: Fútbol',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

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

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
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
          child: _isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Cargando categorías...'),
                    ],
                  ),
                )
              : DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  hint: const Text('Selecciona una categoría'),
                  items: _categories.map((category) {
                    return DropdownMenuItem<Category>(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (Category? category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
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

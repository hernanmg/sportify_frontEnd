import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/category_service.dart';
import 'package:sportify_amateur/core/services/sport_service.dart';
import 'package:sportify_amateur/models/category.dart';
import 'package:sportify_amateur/models/sport.dart';

class CategoriesCatalogTab extends StatefulWidget {
  const CategoriesCatalogTab({super.key});

  @override
  State<CategoriesCatalogTab> createState() => _CategoriesCatalogTabState();
}

class _CategoriesCatalogTabState extends State<CategoriesCatalogTab> {
  final CategoryService _categoryService = CategoryService();
  final SportService _sportService = SportService();

  List<Category> _categories = [];
  List<Sport> _sports = [];
  Sport? _selectedSport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sports = await _sportService.getAllSports();
      final categories = await _categoryService.getAllCategories();
      final selectedId = _selectedSport?.id;
      Sport? selectedSport;
      if (selectedId != null) {
        try {
          selectedSport = sports.firstWhere((s) => s.id == selectedId);
        } catch (_) {
          selectedSport = sports.isNotEmpty ? sports.first : null;
        }
      } else {
        selectedSport = sports.isNotEmpty ? sports.first : null;
      }
      setState(() {
        _sports = sports;
        _categories = categories;
        _selectedSport = selectedSport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error al cargar datos: $e', isError: true);
    }
  }

  List<Category> get _filteredCategories {
    if (_selectedSport == null) return _categories;
    return _categories
        .where((category) => category.sportId == _selectedSport!.id)
        .toList();
  }

  Future<void> _seedCategories() async {
    if (_selectedSport == null) {
      _showSnack('Primero creá al menos un deporte', isError: true);
      return;
    }

    try {
      await _categoryService.seedFootballCategories(
        sportId: _selectedSport!.id,
      );
      _showSnack('Categorías iniciales cargadas para ${_selectedSport!.name}');
      _loadData();
    } catch (e) {
      _showSnack('Error al cargar categorías: $e', isError: true);
    }
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    if (_sports.isEmpty) {
      _showSnack('Primero creá al menos un deporte', isError: true);
      return;
    }

    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');
    final ageMinController =
        TextEditingController(text: category?.ageMin?.toString() ?? '');
    final ageMaxController =
        TextEditingController(text: category?.ageMax?.toString() ?? '');
    final sortOrderController =
        TextEditingController(text: category?.sortOrder.toString() ?? '0');

    Sport selectedSport = category != null
        ? _sports.firstWhere(
            (sport) => sport.id == category.sportId,
            orElse: () => _sports.first,
          )
        : (_selectedSport ?? _sports.first);
    String? gender = category?.gender ?? 'mixto';
    bool isActive = category?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Sport>(
                  value: selectedSport,
                  decoration: const InputDecoration(labelText: 'Deporte'),
                  items: _sports
                      .map(
                        (sport) => DropdownMenuItem(
                          value: sport,
                          child: Text(sport.name),
                        ),
                      )
                      .toList(),
                  onChanged: (sport) {
                    if (sport != null) {
                      setDialogState(() => selectedSport = sport);
                    }
                  },
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: const [
                    DropdownMenuItem(value: 'mixto', child: Text('Mixto')),
                    DropdownMenuItem(
                        value: 'masculino', child: Text('Masculino')),
                    DropdownMenuItem(value: 'femenino', child: Text('Femenino')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => gender = value ?? 'mixto'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageMinController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration:
                            const InputDecoration(labelText: 'Edad mín.'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: ageMaxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration:
                            const InputDecoration(labelText: 'Edad máx.'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Orden'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  value: isActive,
                  onChanged: (value) =>
                      setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(category == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('El nombre es obligatorio', isError: true);
      return;
    }

    final payload = {
      'name': name,
      'sportId': selectedSport.id,
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      'gender': gender,
      'ageMin': ageMinController.text.trim().isEmpty
          ? null
          : int.parse(ageMinController.text.trim()),
      'ageMax': ageMaxController.text.trim().isEmpty
          ? null
          : int.parse(ageMaxController.text.trim()),
      'sortOrder': sortOrderController.text.trim().isEmpty
          ? 0
          : int.parse(sortOrderController.text.trim()),
      'isActive': isActive,
    };

    try {
      if (category == null) {
        await _categoryService.createCategory(payload);
        _showSnack('Categoría creada');
      } else {
        await _categoryService.updateCategory(category.id, payload);
        _showSnack('Categoría actualizada');
      }
      _loadData();
    } catch (e) {
      _showSnack('Error al guardar: $e', isError: true);
    }
  }

  Future<void> _toggleCategory(Category category) async {
    try {
      await _categoryService.toggleCategoryActive(category.id);
      _loadData();
    } catch (e) {
      _showSnack('Error al cambiar estado: $e', isError: true);
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _categoryService.deleteCategory(category.id);
      _showSnack('Categoría eliminada');
      _loadData();
    } catch (e) {
      _showSnack('Error al eliminar: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_sports.isEmpty)
                Text(
                  'No hay deportes. Andá a la pestaña Deportes primero.',
                  style: TextStyle(color: Colors.orange[800]),
                )
              else
                DropdownButtonFormField<Sport>(
                  value: _selectedSport,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por deporte',
                    border: OutlineInputBorder(),
                  ),
                  items: _sports
                      .map(
                        (sport) => DropdownMenuItem(
                          value: sport,
                          child: Text(sport.name),
                        ),
                      )
                      .toList(),
                  onChanged: (sport) => setState(() => _selectedSport = sport),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sports.isEmpty ? null : _seedCategories,
                      icon: const Icon(Icons.download),
                      label: const Text('Cargar categorías base'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text('No hay categorías para este deporte'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _sports.isEmpty ? null : _seedCategories,
                        icon: const Icon(Icons.download),
                        label: const Text('Cargar categorías base'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = _filteredCategories[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.category,
                            color: category.isActive
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        title: Text(category.displayName),
                        subtitle: Text(
                          [
                            category.sportName,
                            category.description,
                            category.isActive ? 'Activa' : 'Inactiva',
                          ].whereType<String>().join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showCategoryDialog(category: category);
                                break;
                              case 'toggle':
                                _toggleCategory(category);
                                break;
                              case 'delete':
                                _deleteCategory(category);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                category.isActive
                                    ? 'Desactivar'
                                    : 'Activar',
                              ),
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
      ],
    );
  }
}

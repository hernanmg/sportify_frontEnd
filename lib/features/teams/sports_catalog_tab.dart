import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/sport_service.dart';
import 'package:sportify_amateur/models/sport.dart';

class SportsCatalogTab extends StatefulWidget {
  const SportsCatalogTab({super.key});

  @override
  State<SportsCatalogTab> createState() => _SportsCatalogTabState();
}

class _SportsCatalogTabState extends State<SportsCatalogTab> {
  final SportService _sportService = SportService();
  List<Sport> _sports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSports();
  }

  Future<void> _loadSports() async {
    setState(() => _isLoading = true);
    try {
      final sports = await _sportService.getAllSports();
      setState(() {
        _sports = sports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error al cargar deportes: $e', isError: true);
    }
  }

  Future<void> _seedDefaults() async {
    try {
      await _sportService.seedDefaults();
      _showSnack('Deportes iniciales cargados');
      _loadSports();
    } catch (e) {
      _showSnack('Error al cargar iniciales: $e', isError: true);
    }
  }

  Future<void> _showSportDialog({Sport? sport}) async {
    final controller = TextEditingController(text: sport?.name ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sport == null ? 'Nuevo deporte' : 'Editar deporte'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Fútbol',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(sport == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = controller.text.trim();
    if (name.length < 2) {
      _showSnack('El nombre debe tener al menos 2 caracteres', isError: true);
      return;
    }

    try {
      if (sport == null) {
        await _sportService.createSport(name);
        _showSnack('Deporte creado');
      } else {
        await _sportService.updateSport(sport.id, name);
        _showSnack('Deporte actualizado');
      }
      _loadSports();
    } catch (e) {
      _showSnack('Error al guardar: $e', isError: true);
    }
  }

  Future<void> _deleteSport(Sport sport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar deporte'),
        content: Text(
          '¿Eliminar "${sport.name}"?\n\n'
          'También se eliminarán sus categorías asociadas.',
        ),
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
      await _sportService.deleteSport(sport.id);
      _showSnack('Deporte eliminado');
      _loadSports();
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Cargá los deportes antes de categorías y equipos.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              TextButton.icon(
                onPressed: _seedDefaults,
                icon: const Icon(Icons.download),
                label: const Text('Cargar iniciales'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text('No hay deportes registrados'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _seedDefaults,
                        icon: const Icon(Icons.download),
                        label: const Text('Cargar Fútbol, Básquet y Vóley'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sports.length,
                  itemBuilder: (context, index) {
                    final sport = _sports[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.sports, color: Colors.blue),
                        ),
                        title: Text(sport.name),
                        subtitle: Text('ID: ${sport.id}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showSportDialog(sport: sport);
                            } else if (value == 'delete') {
                              _deleteSport(sport);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
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

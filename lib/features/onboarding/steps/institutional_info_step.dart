import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/category_service.dart';
import 'package:sportify_amateur/core/services/sport_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/category.dart';
import 'package:sportify_amateur/models/sport.dart';

enum TeamSetupMode { create, join, skip }

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
  TeamSetupMode _mode = TeamSetupMode.skip;
  final _teamNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final SportService _sportService = SportService();
  final CategoryService _categoryService = CategoryService();
  final TeamService _teamService = TeamService();

  List<Sport> _sports = [];
  Sport? _selectedSport;
  List<Category> _categories = [];
  final Set<int> _selectedCategoryIds = {};
  bool _loadingSports = true;
  bool _loadingCategories = false;
  String? _invitePreview;
  bool _previewLoading = false;

  @override
  void initState() {
    super.initState();
    final mode = widget.initialData['onboardingMode'] as String?;
    if (mode == 'create') _mode = TeamSetupMode.create;
    if (mode == 'join') _mode = TeamSetupMode.join;
    _teamNameController.text = widget.initialData['teamName']?.toString() ?? '';
    _inviteCodeController.text =
        widget.initialData['inviteCode']?.toString() ?? '';
    _loadSports();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSports() async {
    setState(() => _loadingSports = true);
    try {
      final sports = await _sportService.getAllSports();
      setState(() {
        _sports = sports;
        _selectedSport = sports.isNotEmpty ? sports.first : null;
      });
      if (_selectedSport != null) await _loadCategories();
    } finally {
      if (mounted) setState(() => _loadingSports = false);
    }
  }

  Future<void> _loadCategories() async {
    if (_selectedSport == null) return;
    setState(() => _loadingCategories = true);
    try {
      final cats =
          await _categoryService.getCategoriesBySport(_selectedSport!.id);
      setState(() {
        _categories = cats;
        _selectedCategoryIds.removeWhere(
          (id) => !cats.any((c) => c.id == id),
        );
      });
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _previewInvite() async {
    final code = _inviteCodeController.text.trim();
    if (code.length < 4) return;
    setState(() {
      _previewLoading = true;
      _invitePreview = null;
    });
    try {
      final data = await _teamService.previewInvite(code);
      setState(() {
        _invitePreview =
            '${data['teamName']} — ${(data['categoryNames'] as List?)?.join(', ') ?? 'Sin categoría'}';
      });
    } catch (e) {
      setState(() => _invitePreview = 'Código no válido');
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  void _handleNext() {
    if (_mode == TeamSetupMode.create) {
      if (_teamNameController.text.trim().length < 2) {
        _snack('Ingresá el nombre del equipo');
        return;
      }
      if (_selectedSport == null) {
        _snack('Seleccioná un deporte');
        return;
      }
      if (_selectedCategoryIds.isEmpty) {
        _snack('Seleccioná al menos una categoría');
        return;
      }
    }
    if (_mode == TeamSetupMode.join &&
        _inviteCodeController.text.trim().length < 4) {
      _snack('Ingresá el código de invitación');
      return;
    }

    widget.onNext({
      'onboardingMode': _mode == TeamSetupMode.create
          ? 'create'
          : _mode == TeamSetupMode.join
              ? 'join'
              : 'skip',
      'teamName': _teamNameController.text.trim(),
      'sportId': _selectedSport?.id,
      'categoryIds': _selectedCategoryIds.toList(),
      'inviteCode': _inviteCodeController.text.trim().toUpperCase(),
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Cómo querés empezar?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _modeTile(
                    TeamSetupMode.create,
                    'Administro / creo un equipo',
                    'Quedás como encargado y recibís un código para invitar al plantel',
                    Icons.shield,
                  ),
                  _modeTile(
                    TeamSetupMode.join,
                    'Me uno con código de invitación',
                    'Tu capitán te comparte un código del equipo',
                    Icons.vpn_key,
                  ),
                  _modeTile(
                    TeamSetupMode.skip,
                    'Lo configuro después',
                    'Podés crear o unirte a un equipo más tarde',
                    Icons.schedule,
                  ),
                  if (_mode == TeamSetupMode.create) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _teamNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del equipo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingSports)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<Sport>(
                        value: _selectedSport,
                        decoration: const InputDecoration(
                          labelText: 'Deporte',
                          border: OutlineInputBorder(),
                        ),
                        items: _sports
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (s) async {
                          setState(() => _selectedSport = s);
                          await _loadCategories();
                        },
                      ),
                    const SizedBox(height: 12),
                    const Text('Categorías del equipo'),
                    if (_loadingCategories)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: _categories.map((cat) {
                          final selected =
                              _selectedCategoryIds.contains(cat.id);
                          return FilterChip(
                            label: Text(cat.name),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedCategoryIds.add(cat.id);
                                } else {
                                  _selectedCategoryIds.remove(cat.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                  if (_mode == TeamSetupMode.join) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _inviteCodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de invitación',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: _previewLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          onPressed: _previewInvite,
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      ],
                    ),
                    if (_invitePreview != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _invitePreview!,
                          style: TextStyle(
                            color: _invitePreview!.contains('no válido')
                                ? Colors.red
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          _bottomButtons(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.groups, color: Colors.orange, size: 32),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu equipo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Creá el club o unite con el código que te pase el encargado',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTile(
    TeamSetupMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final selected = _mode == mode;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? Colors.orange.shade50 : null,
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.orange : Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Radio<TeamSetupMode>(
          value: mode,
          groupValue: _mode,
          onChanged: (v) => setState(() => _mode = v!),
        ),
        onTap: () => setState(() => _mode = mode),
      ),
    );
  }

  Widget _bottomButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onPrevious,
                child: const Text('Anterior'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
        TextButton(onPressed: widget.onSkip, child: const Text('Saltar este paso')),
      ],
    );
  }
}

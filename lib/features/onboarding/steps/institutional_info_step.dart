import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/category_service.dart';
import 'package:sportify_amateur/core/services/sport_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/onboarding/widgets/onboarding_step_buttons.dart';
import 'package:sportify_amateur/core/utils/category_label.dart';
import 'package:sportify_amateur/models/category.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/sport.dart';
import 'package:sportify_amateur/models/team.dart';

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
  bool _seedingCategories = false;
  String? _invitePreview;
  bool _previewLoading = false;
  bool _isPlatformAdmin = false;
  bool _isDt = false;
  List<MyTeamOption> _myTeams = [];
  List<Team> _nameCollisions = [];
  bool _acknowledgeDuplicateName = false;
  bool _checkingTeamName = false;

  static const _fieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  );

  InputDecoration _inputDecoration(String label) {
    return _fieldDecoration.copyWith(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final mode = widget.initialData['onboardingMode'] as String?;
    if (mode == 'create') _mode = TeamSetupMode.create;
    if (mode == 'join') _mode = TeamSetupMode.join;
    _teamNameController.text = widget.initialData['teamName']?.toString() ?? '';
    _inviteCodeController.text =
        widget.initialData['inviteCode']?.toString() ?? '';
    _teamNameController.addListener(_onTeamNameChanged);
    _loadRoleAndSports();
  }

  Future<void> _loadRoleAndSports() async {
    final role = await AuthStorageService().getRole();
    List<MyTeamOption> teams = [];
    try {
      teams = await _teamService.getMyTeams();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isPlatformAdmin =
          role == 'super_admin' || role == 'manager' || role == 'admin';
      _isDt = role == 'dt';
      _myTeams = teams;
      if (teams.isNotEmpty && widget.initialData['onboardingMode'] == null) {
        _mode = TeamSetupMode.skip;
      } else if (_isDt && widget.initialData['onboardingMode'] == null) {
        _mode = TeamSetupMode.join;
      } else if (_isPlatformAdmin &&
          widget.initialData['onboardingMode'] == null) {
        _mode = TeamSetupMode.create;
      }
    });
    await _loadSports();
    if (_teamNameController.text.trim().length >= 2) {
      await _checkExistingTeamName(_teamNameController.text.trim());
    }
  }

  void _onTeamNameChanged() {
    final name = _teamNameController.text.trim();
    if (name.length < 2) {
      if (_nameCollisions.isNotEmpty || _acknowledgeDuplicateName) {
        setState(() {
          _nameCollisions = [];
          _acknowledgeDuplicateName = false;
        });
      }
      return;
    }
    _checkExistingTeamName(name);
  }

  Future<void> _checkExistingTeamName(String name) async {
    if (_selectedSport == null) return;
    setState(() => _checkingTeamName = true);
    try {
      final matches = await _teamService.searchTeams(name);
      final exact = matches
          .where(
            (t) =>
                t.name.toLowerCase() == name.toLowerCase() &&
                t.sportId == _selectedSport!.id,
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _nameCollisions = exact;
        if (exact.isEmpty) _acknowledgeDuplicateName = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _nameCollisions = [];
          _acknowledgeDuplicateName = false;
        });
      }
    } finally {
      if (mounted) setState(() => _checkingTeamName = false);
    }
  }

  bool _isGenericGenderCategory(String name) =>
      CategoryLabels.isGenericGenderOnly(name);

  @override
  void dispose() {
    _teamNameController.removeListener(_onTeamNameChanged);
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

  Future<void> _loadCategories({bool trySeedIfEmpty = true}) async {
    if (_selectedSport == null) return;
    setState(() => _loadingCategories = true);
    try {
      var cats =
          await _categoryService.getCategoriesBySport(_selectedSport!.id);
      if (cats.isEmpty && trySeedIfEmpty) {
        try {
          cats = await _categoryService.seedFootballCategories(
            sportId: _selectedSport!.id,
          );
        } catch (_) {
          // Sin categorías en el servidor; el usuario puede cargarlas manualmente.
        }
      }
      if (!mounted) return;
      final selectable =
          cats.where((c) => !_isGenericGenderCategory(c.name)).toList();
      setState(() {
        _categories = selectable.isNotEmpty ? selectable : cats;
        _selectedCategoryIds.removeWhere(
          (id) => !_categories.any((c) => c.id == id),
        );
      });
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _seedCategories() async {
    if (_selectedSport == null) return;
    setState(() => _seedingCategories = true);
    try {
      final cats = await _categoryService.seedFootballCategories(
        sportId: _selectedSport!.id,
      );
      if (!mounted) return;
      setState(() => _categories = cats);
      _snack('Categorías cargadas (${cats.length})', isError: false);
    } catch (e) {
      _snack('No se pudieron cargar categorías: $e');
    } finally {
      if (mounted) setState(() => _seedingCategories = false);
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
      if (_nameCollisions.isNotEmpty && !_acknowledgeDuplicateName) {
        _snack(
          'Ya hay otro equipo con este nombre. Marcá la confirmación o usá el código de invitación.',
        );
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
      'acknowledgeDuplicateName': _acknowledgeDuplicateName,
    });
  }

  void _snack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green.shade700,
      ),
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
                  if (_myTeams.isNotEmpty) ...[
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Ya tenés equipo asignado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ..._myTeams.map(
                              (t) => Text(
                                '• ${t.displayLabel}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Podés continuar con «Lo configuro después».',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _isPlatformAdmin
                        ? 'Como administrador, creá el primer equipo'
                        : _isDt
                            ? 'Como DT, unite al equipo del club'
                            : '¿Cómo querés empezar?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (_isPlatformAdmin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No necesitás código de invitación: vos gestionás el club.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                  if (_isDt && _myTeams.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Si el administrador ya creó el equipo, pedile el código de invitación '
                      'y unite desde la opción de abajo.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (!_isDt || _isPlatformAdmin)
                    _modeTile(
                      TeamSetupMode.create,
                      _isPlatformAdmin
                          ? 'Crear equipo del club'
                          : 'Administro / creo un equipo',
                      _isPlatformAdmin
                          ? 'Definís deporte, categorías y recibís el código para el plantel'
                          : 'Quedás como encargado y recibís un código para invitar al plantel',
                      Icons.shield,
                      recommended: _isPlatformAdmin,
                    ),
                  if (!_isPlatformAdmin)
                    _modeTile(
                      TeamSetupMode.join,
                      'Me uno con código de invitación',
                      'Tu capitán o DT te comparte un código del equipo',
                      Icons.vpn_key,
                    ),
                  _modeTile(
                    TeamSetupMode.skip,
                    'Lo configuro después',
                    _isPlatformAdmin
                        ? 'Creá el equipo desde Inicio → Crear equipo o Menú → Gestión de equipos'
                        : 'Podés crear o unirte a un equipo más tarde',
                    Icons.schedule,
                  ),
                  if (_mode == TeamSetupMode.create) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _teamNameController,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                      ),
                      decoration: _inputDecoration('Nombre del equipo'),
                    ),
                    if (_checkingTeamName)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      )
                    else if (_nameCollisions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ya hay ${_nameCollisions.length} equipo(s) con este nombre:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ..._nameCollisions.map((t) {
                                  final admins = t.adminEmails.isNotEmpty
                                      ? t.adminEmails.join(', ')
                                      : 'sin admin registrado';
                                  return Text(
                                    '• ${t.name} — admin: $admins',
                                    style: const TextStyle(fontSize: 12),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Text(
                                  'Si es el tuyo, pedí el código al administrador. '
                                  'Si es otro club distinto, confirmá abajo.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Confirmo que es un club distinto con el mismo nombre',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _acknowledgeDuplicateName,
                        onChanged: (v) => setState(
                          () => _acknowledgeDuplicateName = v ?? false,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_loadingSports)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<Sport>(
                        value: _selectedSport,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration('Deporte'),
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
                    const SizedBox(height: 16),
                    Text(
                      'Categorías del equipo *',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elegí al menos una (ej. M+35, M+40, M-Libre)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingCategories)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      )
                    else if (_categories.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No hay categorías para este deporte.',
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                onPressed:
                                    _seedingCategories ? null : _seedCategories,
                                icon: _seedingCategories
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: const Text(
                                  'Cargar categorías de fútbol',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
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
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                      decoration: _inputDecoration('Código de invitación').copyWith(
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
          OnboardingStepButtons(
            onPrevious: widget.onPrevious,
            onPrimary: _handleNext,
            primaryLabel: 'Continuar',
            primaryColor: Colors.orange,
            onSkip: widget.onSkip,
          ),
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
    IconData icon, {
    bool recommended = false,
  }) {
    final selected = _mode == mode;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? Colors.orange.shade50 : null,
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.orange : Colors.grey),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recomendado',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
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
}

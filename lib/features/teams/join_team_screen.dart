import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';

/// Unirse a un equipo con código (también disponible en onboarding).
class JoinTeamScreen extends StatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final _codeController = TextEditingController();
  final _teamService = TeamService();
  bool _loading = false;
  String? _previewText;
  bool _isStaff = false;
  bool _alsoPlayOnRoster = false;
  List<int> _inviteCategoryIds = [];
  List<String> _inviteCategoryNames = [];
  final Set<int> _selectedCategoryIds = {};

  static const _staffRoles = {'dt', 'super_admin', 'manager', 'admin', 'team_captain'};

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthStorageService().getRole();
    if (!mounted) return;
    setState(() => _isStaff = _staffRoles.contains(role));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _resetPreview() {
    _previewText = null;
    _inviteCategoryIds = [];
    _inviteCategoryNames = [];
    _selectedCategoryIds.clear();
    _alsoPlayOnRoster = false;
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 4) return;
    setState(() => _loading = true);
    try {
      final data = await _teamService.previewInvite(code);
      final names = (data['categoryNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final ids = (data['categoryIds'] as List?)
              ?.map((e) => int.tryParse(e.toString()))
              .whereType<int>()
              .toList() ??
          [];
      setState(() {
        _previewText = 'Te unirás a: ${data['teamName']}'
            '${names.isNotEmpty ? ' (${names.join(', ')})' : ''}';
        _inviteCategoryIds = ids;
        _inviteCategoryNames = names;
        _selectedCategoryIds
          ..clear()
          ..addAll(ids);
        _alsoPlayOnRoster = false;
      });
    } catch (e) {
      setState(() {
        _resetPreview();
        _previewText = TeamService.errorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<int> _categoryIdsForJoin() {
    if (_isStaff) {
      return _alsoPlayOnRoster ? _selectedCategoryIds.toList() : [];
    }
    return _inviteCategoryIds.isNotEmpty
        ? _inviteCategoryIds
        : _selectedCategoryIds.toList();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá el código')),
      );
      return;
    }
    if (_isStaff && _alsoPlayOnRoster && _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná al menos una categoría')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final categoryIds = _categoryIdsForJoin();
      final result = await _teamService.joinWithCode(
        code,
        categoryIds: categoryIds.isNotEmpty ? categoryIds : null,
      );
      final newRole = result['role']?.toString();
      if (newRole != null && newRole.isNotEmpty) {
        await AuthStorageService().saveRole(newRole);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? '¡Listo!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TeamService.errorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _staffRosterSection() {
    if (!_isStaff || _previewText == null || _previewText!.contains('inválido')) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('También juego en el plantel'),
              subtitle: const Text(
                'Como DT podés gestionar el equipo sin estar en la lista de jugadores. '
                'Activá esto si además jugás partidos.',
              ),
              value: _alsoPlayOnRoster,
              onChanged: (v) => setState(() => _alsoPlayOnRoster = v),
            ),
            if (_alsoPlayOnRoster) ...[
              const SizedBox(height: 8),
              const Text(
                'Categoría(s) en las que jugás',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_inviteCategoryIds.isEmpty)
                Text(
                  'El código no trae categorías. Pedile al admin que genere '
                  'un código con categoría o agregate desde Plantel.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: List.generate(_inviteCategoryIds.length, (i) {
                    final id = _inviteCategoryIds[i];
                    final label = i < _inviteCategoryNames.length
                        ? _inviteCategoryNames[i]
                        : 'Cat. $id';
                    return FilterChip(
                      label: Text(label),
                      selected: _selectedCategoryIds.contains(id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(id);
                          } else {
                            _selectedCategoryIds.remove(id);
                          }
                        });
                      },
                    );
                  }),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intro = _isStaff
        ? 'Como cuerpo técnico te unís al equipo para gestionarlo. '
            'Si también jugás, podés sumarte al plantel.'
        : 'Pedile el código al encargado del equipo. Al unirte quedás en el plantel.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirme a un equipo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(intro),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código de invitación',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              ],
              onChanged: (_) {
                if (_previewText != null) {
                  setState(_resetPreview);
                }
              },
            ),
            if (_previewText != null) ...[
              const SizedBox(height: 12),
              Text(
                _previewText!,
                style: TextStyle(
                  color: _previewText!.toLowerCase().contains('inválido')
                      ? Colors.red
                      : Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            _staffRosterSection(),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loading ? null : _verifyCode,
              child: const Text('Verificar código'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isStaff ? 'Unirme al equipo' : 'Unirme'),
            ),
          ],
        ),
      ),
    );
  }
}

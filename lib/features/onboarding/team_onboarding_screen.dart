import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/services/category_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/sports/roster_form_improved_screen.dart';
import 'package:sportify_amateur/models/category.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:provider/provider.dart';

/// Flujo unificado: invitación + categorías + alta en buena fe.
class TeamOnboardingScreen extends StatefulWidget {
  const TeamOnboardingScreen({super.key});

  @override
  State<TeamOnboardingScreen> createState() => _TeamOnboardingScreenState();
}

class _TeamOnboardingScreenState extends State<TeamOnboardingScreen> {
  final _teamService = TeamService();
  final _categoryService = CategoryService();
  final _pageController = PageController();

  List<MyTeamOption> _teams = [];
  MyTeamOption? _selectedTeam;
  List<Category> _categories = [];
  final Set<int> _selectedCategoryIds = {};
  String? _inviteCode;
  bool _loading = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() => _loading = true);
    try {
      final teams = MyTeamOption.dedupeByTeamId(await _teamService.getMyTeams());
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _selectedTeam = teams.isNotEmpty ? teams.first : null;
        _loading = false;
      });
      if (_selectedTeam != null) await _loadCategories();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamService.errorMessage(e))),
        );
      }
    }
  }

  Future<void> _loadCategories() async {
    final team = _selectedTeam;
    if (team == null) return;
    try {
      final sportId = team.team.sportId;
      if (sportId == null) {
        setState(() => _categories = []);
        return;
      }
      final cats =
          await _categoryService.getCategoriesBySport(sportId);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedCategoryIds
          ..clear()
          ..addAll(
            team.categoryIds.isNotEmpty
                ? team.categoryIds
                : (team.team.categoryId != null
                    ? [team.team.categoryId!]
                    : []),
          );
      });
    } catch (_) {
      setState(() => _categories = []);
    }
  }

  Future<void> _generateInvite() async {
    final team = _selectedTeam;
    if (team == null) return;
    setState(() => _loading = true);
    try {
      final result = await _teamService.createTeamInvite(
        team.teamId,
        categoryIds: _selectedCategoryIds.isEmpty
            ? null
            : _selectedCategoryIds.toList(),
      );
      setState(() => _inviteCode = result['code']?.toString());
      _goToStep(1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TeamService.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openRosterForm() async {
    final season = context.read<SeasonProvider>().season;
    final team = _selectedTeam;
    if (team == null) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RosterFormImprovedScreen(
          season: season,
          teamId: team.teamId,
        ),
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jugador agregado a la lista de buena fe'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _copyCode() {
    if (_inviteCode == null) return;
    Clipboard.setData(ClipboardData(text: _inviteCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _teams.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alta en el equipo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_teams.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alta en el equipo')),
        body: const Center(
          child: Text('Necesitás pertenecer a un equipo como staff'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding del equipo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: Colors.teal.shade100,
            color: Colors.teal,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _stepChip(0, 'Invitación'),
                _stepChip(1, 'Código'),
                _stepChip(2, 'Buena fe'),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInviteStep(),
                _buildCodeStep(),
                _buildRosterStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepChip(int index, String label) {
    final active = _step == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Chip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          backgroundColor: active ? Colors.teal.shade100 : null,
        ),
      ),
    );
  }

  Widget _buildInviteStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1. Elegí el equipo y las categorías para la invitación.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MyTeamOption>(
            value: _selectedTeam,
            decoration: const InputDecoration(
              labelText: 'Equipo',
              border: OutlineInputBorder(),
            ),
            items: _teams
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.name)),
                )
                .toList(),
            onChanged: (t) async {
              setState(() => _selectedTeam = t);
              await _loadCategories();
            },
          ),
          const SizedBox(height: 16),
          if (_categories.isNotEmpty) ...[
            const Text('Categorías incluidas en el código:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((c) {
                final selected = _selectedCategoryIds.contains(c.id);
                return FilterChip(
                  label: Text(c.displayName),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedCategoryIds.add(c.id);
                      } else {
                        _selectedCategoryIds.remove(c.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _generateInvite,
            icon: const Icon(Icons.vpn_key),
            label: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generar código de invitación'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '2. Compartí el código. Quien se registre y lo use quedará en el plantel.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          if (_inviteCode != null)
            SelectableText(
              _inviteCode!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _inviteCode == null ? null : _copyCode,
            icon: const Icon(Icons.copy),
            label: const Text('Copiar código'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => _goToStep(2),
            child: const Text('Continuar: alta en buena fe'),
          ),
          TextButton(
            onPressed: () => _goToStep(0),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '3. Cargá la ficha en lista de buena fe (jugador ya en el club o invitado presencial).',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openRosterForm,
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar jugador en buena fe'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/finance/ledger_tab.dart';
import 'package:sportify_amateur/features/finance/my_account_tab.dart';
import 'package:sportify_amateur/features/finance/team_finance_tab.dart';
import 'package:sportify_amateur/models/team.dart';

class FinanceHubScreen extends StatefulWidget {
  const FinanceHubScreen({super.key});

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> {
  final TeamService _teamService = TeamService();
  final _myAccountKey = GlobalKey<MyAccountTabState>();
  final _teamFinanceKey = GlobalKey<TeamFinanceTabState>();
  final _ledgerKey = GlobalKey<LedgerTabState>();

  List<Team> _teams = [];
  Team? _selectedTeam;
  bool _isManager = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final role = await AuthStorageService().getRole();
    final isManager = role == 'manager' || role == 'super_admin';

    List<Team> teams = [];
    try {
      teams = await _teamService.getAllTeams();
    } catch (_) {
      teams = [];
    }

    if (!mounted) return;

    setState(() {
      _isManager = isManager;
      _teams = teams;
      _selectedTeam = teams.isNotEmpty ? teams.first : null;
      _ready = true;
    });
  }

  void _onTeamChanged(int? teamId) {
    if (teamId == null) return;
    final team = _teams.firstWhere((t) => t.id == teamId);
    setState(() => _selectedTeam = team);
    _myAccountKey.currentState?.reload();
    _teamFinanceKey.currentState?.reload();
    _ledgerKey.currentState?.reload();
  }

  Future<void> _refreshCurrentTab(TabController controller) async {
    final index = controller.index;
    if (index == 0) {
      await _myAccountKey.currentState?.reload();
    } else if (_isManager && index == 1) {
      await _teamFinanceKey.currentState?.reload();
    } else {
      await _ledgerKey.currentState?.reload();
    }
  }

  Widget _buildTeamSelector(BuildContext context) {
    if (_teams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('No hay equipos disponibles'),
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: DropdownButtonFormField<int>(
          key: ValueKey(_selectedTeam?.id),
          initialValue: _selectedTeam?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Equipo',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _teams
              .map(
                (team) => DropdownMenuItem(
                  value: team.id,
                  child: Text(team.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _onTeamChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tabCount = _isManager ? 3 : 2;

    return DefaultTabController(
      length: tabCount,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Finanzas'),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              bottom: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  const Tab(icon: Icon(Icons.person), text: 'Mi cuenta'),
                  if (_isManager)
                    const Tab(icon: Icon(Icons.groups), text: 'Equipo'),
                  const Tab(
                    icon: Icon(Icons.receipt_long),
                    text: 'Movimientos',
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshCurrentTab(tabController),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTeamSelector(context),
                Expanded(
                  child: TabBarView(
                    children: [
                      MyAccountTab(
                        key: _myAccountKey,
                        teamId: _selectedTeam?.id,
                      ),
                      if (_isManager)
                        TeamFinanceTab(
                          key: _teamFinanceKey,
                          teamId: _selectedTeam?.id,
                        ),
                      LedgerTab(
                        key: _ledgerKey,
                        teamId: _selectedTeam?.id,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

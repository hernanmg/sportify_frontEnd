import 'package:flutter/material.dart';
import 'package:sportify_amateur/widgets/keepsync_card_tabs.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/widgets/season_selector_chip.dart';
import 'package:sportify_amateur/core/common/active_workspace_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/features/finance/ledger_tab.dart';
import 'package:sportify_amateur/features/finance/my_account_tab.dart';
import 'package:sportify_amateur/features/finance/team_finance_tab.dart';
import 'package:sportify_amateur/features/finance/quota_overview_screen.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/team.dart';

class FinanceHubScreen extends StatefulWidget {
  const FinanceHubScreen({super.key});

  @override
  State<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends State<FinanceHubScreen> {
  final _myAccountKey = GlobalKey<MyAccountTabState>();
  final _teamFinanceKey = GlobalKey<TeamFinanceTabState>();
  final _ledgerKey = GlobalKey<LedgerTabState>();

  String? _role;
  bool _seasonEndBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final workspace = context.read<ActiveWorkspaceProvider>();
        workspace.load();
        final season = context.read<SeasonProvider>();
        season.load().then((_) {
          if (workspace.teamId != null) {
            season.bindTeam(workspace.teamId);
          }
        });
      }
    });
  }

  Future<void> _loadRole() async {
    final role = await AuthStorageService().getRole();
    if (mounted) setState(() => _role = role);
  }

  bool _userCanManageFinanceForTeam(
    String? role,
    Team? team,
    List<MyTeamOption> teamOptions,
  ) {
    if (team == null) return false;
    if (UserCapabilities.isPlatformAdmin(role)) return true;
    final opt = MyTeamOption.findInList(teamOptions, team.id);
    if (opt?.canManageFinance == true) return true;
    if (UserCapabilities.canManageTeamFinance(role)) {
      return teamOptions.any((t) => t.teamId == team.id);
    }
    return false;
  }

  Future<void> _refreshCurrentTab(TabController controller) async {
    final canManage = _userCanManageFinanceForTeam(
      _role,
      context.read<ActiveWorkspaceProvider>().team,
      context.read<ActiveWorkspaceProvider>().teamOptions,
    );
    final index = controller.index;
    if (index == 0) {
      await _myAccountKey.currentState?.reload();
    } else if (canManage && index == 1) {
      await _teamFinanceKey.currentState?.reload();
    } else {
      await _ledgerKey.currentState?.reload();
    }
  }

  Widget _buildCategorySelector(ActiveWorkspaceProvider workspace) {
    if (!workspace.hasMultipleCategories) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: DropdownButtonFormField<int?>(
          key: ValueKey('fin-cat-${workspace.teamId}-${workspace.categoryId}'),
          initialValue: workspace.categoryId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Todas las categorías'),
            ),
            ...workspace.categories.map(
              (c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (v) async {
            await workspace.setCategoryId(v);
            _teamFinanceKey.currentState?.reload();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<ActiveWorkspaceProvider>();
    final selectedTeam = workspace.team;

    if (!workspace.ready) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canManageFinance = _userCanManageFinanceForTeam(
      _role,
      selectedTeam,
      workspace.teamOptions,
    );
    final tabCount = canManageFinance ? 3 : 2;
    final tabItems = <KeepSyncTabItem>[
      const KeepSyncTabItem(
        icon: Icons.person_rounded,
        label: 'Mi cuenta',
        subtitle: 'Cuotas y pagos',
      ),
      if (canManageFinance)
        const KeepSyncTabItem(
          icon: Icons.groups_rounded,
          label: 'Equipo',
          subtitle: 'Caja y resumen',
        ),
      const KeepSyncTabItem(
        icon: Icons.receipt_long_rounded,
        label: 'Movimientos',
        subtitle: 'Ledger',
      ),
    ];

    return DefaultTabController(
      length: tabCount,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return Scaffold(
            appBar: AppBar(
              title: Text(
                selectedTeam != null
                    ? 'Finanzas · ${selectedTeam.name}'
                    : 'Finanzas',
              ),
              actions: [
                const SeasonSelectorChip(),
                IconButton(
                  icon: const Icon(Icons.groups),
                  tooltip: 'Cuotas del plantel',
                  onPressed: selectedTeam == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuotaOverviewScreen(
                                teamId: selectedTeam.id,
                              ),
                            ),
                          );
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _refreshCurrentTab(tabController),
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeepSyncCardTabs.fromController(
                  controller: tabController,
                  items: tabItems,
                ),
                if (selectedTeam == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Seleccioná tu equipo activo para ver finanzas.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Consumer<SeasonProvider>(
                  builder: (context, season, _) {
                    if (!season.isSeasonEnded ||
                        _seasonEndBannerDismissed ||
                        !canManageFinance) {
                      return const SizedBox.shrink();
                    }
                    return MaterialBanner(
                      content: Text(
                        'La temporada ${season.season} ya venció. '
                        'Podés hacer el cierre de caja (cuotas pendientes '
                        'pasan por defecto como saldo a cobrar).',
                      ),
                      leading: const Icon(Icons.lock_clock),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() => _seasonEndBannerDismissed = true);
                            tabController.animateTo(canManageFinance ? 1 : 0);
                          },
                          child: const Text('Ir a Equipo'),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => _seasonEndBannerDismissed = true,
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    );
                  },
                ),
                _buildCategorySelector(workspace),
                Expanded(
                  child: TabBarView(
                    children: [
                      MyAccountTab(
                        key: _myAccountKey,
                        teamId: selectedTeam?.id,
                      ),
                      if (canManageFinance)
                        TeamFinanceTab(
                          key: _teamFinanceKey,
                          teamId: selectedTeam?.id,
                          categoryId: workspace.categoryId,
                        ),
                      LedgerTab(
                        key: _ledgerKey,
                        teamId: selectedTeam?.id,
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

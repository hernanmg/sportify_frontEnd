import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/features/finance/finance_export_helper.dart';
import 'package:sportify_amateur/models/finance.dart';

enum _LedgerScope { all, team, events }

class LedgerTab extends StatefulWidget {
  final int? teamId;

  const LedgerTab({super.key, required this.teamId});

  @override
  State<LedgerTab> createState() => LedgerTabState();
}

class LedgerTabState extends State<LedgerTab> {
  final FinanceService _financeService = FinanceService();
  List<LedgerEntry> _entries = [];
  bool _loading = true;
  String? _error;
  _LedgerScope _scope = _LedgerScope.all;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant LedgerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      reload();
    }
  }

  Future<void> reload() async {
    if (widget.teamId == null) {
      setState(() {
        _loading = false;
        _entries = [];
        _error = 'Seleccioná un equipo';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final scope = switch (_scope) {
        _LedgerScope.all => 'all',
        _LedgerScope.team => 'team',
        _LedgerScope.events => 'events',
      };
      final entries = await _financeService.getTeamLedger(
        widget.teamId!,
        limit: 200,
        scope: scope,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FinanceService.errorMessage(e);
        _loading = false;
      });
    }
  }

  List<LedgerEntry> get _filtered => _entries;

  Future<void> _export(String kind) async {
    final items = _filtered;
    try {
      if (kind == 'csv') {
        await FinanceExportHelper.shareLedgerCsv(entries: items);
      } else {
        await FinanceExportHelper.shareLedgerPdf(
          entries: items,
          teamLabel: 'Equipo #${widget.teamId}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.teamId == null) {
      return const Center(child: Text('Seleccioná un equipo arriba'));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: reload, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final items = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Finanzas de equipo y de eventos están separadas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Exportar',
                    icon: const Icon(Icons.ios_share),
                    onSelected: _export,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'csv',
                        child: Text('Exportar CSV'),
                      ),
                      PopupMenuItem(
                        value: 'pdf',
                        child: Text('Exportar PDF'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<_LedgerScope>(
                segments: const [
                  ButtonSegment(
                    value: _LedgerScope.all,
                    label: Text('Todos'),
                    icon: Icon(Icons.list, size: 16),
                  ),
                  ButtonSegment(
                    value: _LedgerScope.team,
                    label: Text('Equipo'),
                    icon: Icon(Icons.groups, size: 16),
                  ),
                  ButtonSegment(
                    value: _LedgerScope.events,
                    label: Text('Eventos'),
                    icon: Icon(Icons.event, size: 16),
                  ),
                ],
                selected: {_scope},
                onSelectionChanged: (s) {
                  setState(() => _scope = s.first);
                  reload();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Sin movimientos en este filtro')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      final isIncome = entry.isIncome;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            child: Icon(
                              entry.isEventRelated
                                  ? Icons.event
                                  : (isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward),
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(entry.description),
                          subtitle: Text(
                            [
                              entry.isEventRelated ? 'Evento' : 'Equipo',
                              entry.category,
                              if (entry.createdAt != null) entry.createdAt!,
                            ].join(' · '),
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}${formatMoney(entry.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

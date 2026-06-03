import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/models/finance.dart';

class QuotaOverviewScreen extends StatefulWidget {
  final int teamId;

  const QuotaOverviewScreen({super.key, required this.teamId});

  @override
  State<QuotaOverviewScreen> createState() => _QuotaOverviewScreenState();
}

class _QuotaOverviewScreenState extends State<QuotaOverviewScreen> {
  final _finance = FinanceService();
  QuotaOverview? _overview;
  bool _loading = true;
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = await AuthStorageService().getRole();
    _isManager = role == 'super_admin' || role == 'manager' || role == 'admin';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final overview = await _finance.getQuotaOverview(widget.teamId);
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FinanceService.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateMonthly() async {
    final amountCtrl = TextEditingController();
    final now = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar cuota del mes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mes ${now.month}/${now.year}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto por jugador',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    try {
      final season = RosterService.getSeasons().first;
      await _finance.generateMonthlyQuota(
        teamId: widget.teamId,
        year: now.year,
        month: now.month,
        amount: amount,
        season: season,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuotas generadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FinanceService.errorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendReminders() async {
    try {
      final r = await _finance.sendQuotaReminders(
        widget.teamId,
        concept: _overview?.concept,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recordatorios enviados: ${r['sent']}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FinanceService.errorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _overview;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de cuotas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : o == null
              ? const Center(child: Text('Sin datos'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Card(
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (o.concept != null)
                                      Text(
                                        o.concept!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Todo el plantel puede ver quién está al día. '
                                      'La responsabilidad es del grupo.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _chip(
                                          'Al día',
                                          '${o.paidCount}',
                                          Colors.green,
                                        ),
                                        _chip(
                                          'Deben',
                                          '${o.pendingCount}',
                                          Colors.orange,
                                        ),
                                        _chip(
                                          'Total',
                                          formatMoney(o.totalOutstanding),
                                          Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...o.players.map((p) {
                              return ListTile(
                                tileColor: p.isPaid
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                title: Text(p.userName),
                                subtitle: Text(
                                  p.isPaid
                                      ? 'Al día'
                                      : 'Debe ${formatMoney(p.balance)}',
                                ),
                                trailing: Icon(
                                  p.isPaid
                                      ? Icons.check_circle
                                      : Icons.warning_amber,
                                  color: p.isPaid ? Colors.green : Colors.orange,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    if (_isManager)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _generateMonthly,
                                  icon: const Icon(Icons.add_card),
                                  label: const Text('Cuota del mes'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _sendReminders,
                                  icon: const Icon(Icons.notifications),
                                  label: const Text('Recordar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

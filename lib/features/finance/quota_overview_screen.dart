import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/active_workspace_provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
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
  List<QuotaSeries> _series = [];
  bool _loading = true;
  bool _canManageFinance = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final role = await AuthStorageService().getRole();
    _canManageFinance = UserCapabilities.isPlatformAdmin(role) ||
        role == 'dt' ||
        role == 'tesorero' ||
        role == 'delegado';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final season = context.read<SeasonProvider>().season;
      final categoryId = context.read<ActiveWorkspaceProvider>().categoryId;
      final overview = await _finance.getQuotaOverview(
        widget.teamId,
        season: season,
        categoryId: categoryId,
      );
      List<QuotaSeries> series = [];
      if (_canManageFinance) {
        try {
          series = await _finance.listQuotaSeries(widget.teamId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _series = series;
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
    final season = context.read<SeasonProvider>().season;

    try {
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

  Future<void> _generateRecurring() async {
    final amountCtrl = TextEditingController();
    final monthsCtrl = TextEditingController(text: '6');
    final now = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cuota recurrente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Desde ${now.month}/${now.year}'),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto mensual por jugador',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: monthsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad de meses',
                helperText: 'Ej: 6 genera 6 cuotas mensuales',
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
            child: const Text('Generar serie'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    final monthCount = int.tryParse(monthsCtrl.text.trim());
    if (amount == null || amount <= 0 || monthCount == null || monthCount < 1) {
      return;
    }
    final season = context.read<SeasonProvider>().season;

    try {
      await _finance.generateRecurringMonthlyQuota(
        teamId: widget.teamId,
        year: now.year,
        month: now.month,
        amount: amount,
        monthCount: monthCount,
        season: season,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Serie de $monthCount meses generada'),
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

  Future<void> _editSeries(QuotaSeries series) async {
    final amountCtrl =
        TextEditingController(text: series.amount.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar serie de cuotas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${series.monthSpan} mes(es) · ${series.concepts.first}${series.concepts.length > 1 ? ' … ${series.concepts.last}' : ''}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nuevo monto (solo cuotas pendientes)',
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    try {
      await _finance.updateQuotaSeries(series.recurringGroupId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serie actualizada'),
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

  Future<void> _deleteSeries(QuotaSeries series) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar serie'),
        content: Text(
          '¿Eliminar las cuotas pendientes de esta serie?\n'
          '(${series.pendingCount} pendientes). Las ya pagadas se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final result =
          await _finance.deleteQuotaSeries(series.recurringGroupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Serie eliminada',
          ),
          backgroundColor: Colors.green,
        ),
      );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final onVariant = theme.colorScheme.onSurfaceVariant;

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
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerHigh
                                  : Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (o.concept != null)
                                      Text(
                                        o.concept!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: onSurface,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Todo el plantel puede ver quién está al día. '
                                      'La responsabilidad es del grupo.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: onVariant),
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
                            if (_canManageFinance && _series.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Series de cuotas',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._series.map(
                                (s) => Card(
                                  child: ListTile(
                                    title: Text(
                                      '\$${s.amount.toStringAsFixed(0)} × ${s.monthSpan} meses',
                                    ),
                                    subtitle: Text(
                                      '${s.pendingCount} pendientes · ${s.paidCount} pagadas',
                                    ),
                                    trailing: Wrap(
                                      spacing: 0,
                                      children: [
                                        IconButton(
                                          tooltip: 'Editar monto pendiente',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _editSeries(s),
                                        ),
                                        IconButton(
                                          tooltip: 'Eliminar cuotas pendientes',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteSeries(s),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ...o.players.map((p) {
                              return ListTile(
                                tileColor: p.isPaid
                                    ? (isDark
                                        ? Colors.green.withValues(alpha: 0.22)
                                        : Colors.green.shade50)
                                    : (isDark
                                        ? Colors.orange.withValues(alpha: 0.22)
                                        : Colors.orange.shade50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                title: Text(
                                  p.userName,
                                  style: TextStyle(
                                    color: onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  p.isPaid
                                      ? 'Al día'
                                      : 'Debe ${formatMoney(p.balance)}',
                                  style: TextStyle(color: onVariant),
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
                    if (_canManageFinance)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
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
                                    child: OutlinedButton.icon(
                                      onPressed: _generateRecurring,
                                      icon: const Icon(Icons.event_repeat),
                                      label: const Text('Serie'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _sendReminders,
                                  icon: const Icon(Icons.notifications),
                                  label: const Text('Recordar cuotas pendientes'),
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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

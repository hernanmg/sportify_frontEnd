import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/navigation/app_navigator.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/models/finance.dart';
import 'package:sportify_amateur/models/sport_event.dart';

/// Cobro post-entrenamiento: gastos sumados y repartidos entre confirmados.
class TrainingEventFinanceCard extends StatefulWidget {
  final SportEvent event;
  final bool isManager;

  const TrainingEventFinanceCard({
    super.key,
    required this.event,
    required this.isManager,
  });

  @override
  State<TrainingEventFinanceCard> createState() =>
      _TrainingEventFinanceCardState();
}

class _TrainingEventFinanceCardState extends State<TrainingEventFinanceCard> {
  final _finance = FinanceService();
  TrainingCollectionView? _view;
  bool _loading = true;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final raw = await AuthStorageService().getUserId();
    _myUserId = raw != null ? int.tryParse(raw) : null;
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final view = await _finance.getTrainingCollection(widget.event.id);
      if (!mounted) return;
      setState(() {
        _view = view;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _registerExpense() async {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar gasto del entreno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (ej. Cancha, Agua)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto',
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
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    try {
      await _finance.createTrainingExpense(
        teamId: widget.event.teamId,
        sportEventId: widget.event.id,
        amount: amount,
        description: descCtrl.text.trim().isEmpty
            ? 'Gasto entrenamiento'
            : descCtrl.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Gasto sumado al total. El aporte por jugador se actualiza '
            'según confirmaciones.',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Finanzas',
            onPressed: () {
              AppNavigator.state?.pushNamed('/finances');
            },
          ),
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

  Future<void> _payMyShare(TrainingCollectionPlayer row) async {
    if (row.chargeId == null || row.balance <= 0) return;
    final method = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Registrar mi pago'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'transfer'),
            child: const Text('Transferencia'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'cash'),
            child: const Text('Efectivo'),
          ),
        ],
      ),
    );
    if (method == null) return;

    try {
      await _finance.submitPayment(
        teamId: widget.event.teamId,
        amount: row.balance,
        method: method,
        feeChargeIds: [row.chargeId!],
        notes: 'Entreno: ${widget.event.title}',
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago acreditado en tu cuenta del entreno'),
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
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final view = _view;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Gastos y cobro del entrenamiento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Los gastos se suman y se reparten entre quienes confirmaron '
              'asistencia. Al confirmar más jugadores, baja el monto por persona.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (view != null && view.totalExpense > 0) ...[
              Text(
                'Total gastos: ${formatMoney(view.totalExpense)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Confirmados: ${view.confirmedCount} · '
                'Aporte c/u: ${view.amountPerPlayer != null ? formatMoney(view.amountPerPlayer!) : '—'}',
              ),
              if (view.expenses.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...view.expenses.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· ${e.description}: ${formatMoney(e.amount)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ] else
              const Text('Sin gastos cargados todavía.'),
            if (widget.isManager) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _registerExpense,
                icon: const Icon(Icons.add),
                label: const Text('Agregar gasto (cancha, agua, etc.)'),
              ),
            ],
            if (view != null && view.players.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Pagaron ${view.summary.paid} de ${view.summary.total}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...view.players.map((p) {
                final isMe = _myUserId != null && p.userId == _myUserId;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.userName),
                  subtitle: Text(
                    p.isPaid
                        ? 'Pagado'
                        : 'Debe ${formatMoney(p.balance)}',
                  ),
                  trailing: p.isPaid
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : (isMe
                          ? TextButton(
                              onPressed: () => _payMyShare(p),
                              child: const Text('Yo pagué'),
                            )
                          : const Icon(
                              Icons.hourglass_empty,
                              color: Colors.orange,
                            )),
                );
              }),
            ] else if (view != null && view.totalExpense > 0) ...[
              const SizedBox(height: 8),
              const Text(
                'Nadie confirmó aún: el reparto aparece cuando haya confirmados.',
                style: TextStyle(fontSize: 13, color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

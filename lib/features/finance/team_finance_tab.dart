import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/features/finance/payment_receipt_dialog.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/models/finance.dart';

class TeamFinanceTab extends StatefulWidget {
  final int? teamId;

  const TeamFinanceTab({super.key, required this.teamId});

  @override
  State<TeamFinanceTab> createState() => TeamFinanceTabState();
}

class TeamFinanceTabState extends State<TeamFinanceTab> {
  final FinanceService _financeService = FinanceService();
  TeamFinanceSummary? _summary;
  List<PlayerBalance> _balances = [];
  List<PlayerPayment> _pendingPayments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SeasonProvider>().addListener(_onSeasonChanged);
      }
    });
  }

  void _onSeasonChanged() => reload();

  @override
  void dispose() {
    try {
      context.read<SeasonProvider>().removeListener(_onSeasonChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TeamFinanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      reload();
    }
  }

  Future<void> reload() async {
    if (widget.teamId == null) {
      setState(() {
        _loading = false;
        _error = 'Seleccioná un equipo';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final teamId = widget.teamId!;
      final season = context.read<SeasonProvider>().season;
      final results = await Future.wait([
        _financeService.getTeamSummary(teamId),
        _financeService.getTeamPlayerBalances(teamId, season: season),
        _financeService.getPendingPayments(teamId),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as TeamFinanceSummary;
        _balances = results[1] as List<PlayerBalance>;
        _pendingPayments = results[2] as List<PlayerPayment>;
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

  Future<void> _confirmPayment(PlayerPayment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Text(
          '¿Confirmar ${formatMoney(payment.amount)} de '
          '${payment.userName ?? 'jugador #${payment.userId}'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _financeService.confirmPayment(payment.id);
      _showSnack('Pago confirmado y acreditado');
      await reload();
    } catch (e) {
      _showSnack(FinanceService.errorMessage(e));
    }
  }

  Future<void> _rejectPayment(PlayerPayment payment) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar pago'),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    try {
      await _financeService.rejectPayment(
        payment.id,
        reason: reason.isEmpty ? null : reason,
      );
      _showSnack('Pago rechazado');
      await reload();
    } catch (e) {
      _showSnack(FinanceService.errorMessage(e));
    }
  }

  Future<void> _showGenerateFeesDialog() async {
    final conceptController = TextEditingController(text: 'Cuota mensual');
    final amountController = TextEditingController();
    final seasons = RosterService.getSeasons();
    String selectedSeason = context.read<SeasonProvider>().season;
    DateTime? selectedDueDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generar cuotas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: conceptController,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Monto'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vencimiento'),
                  subtitle: Text(
                    selectedDueDate == null
                        ? 'Sin fecha (opcional)'
                        : _formatDate(selectedDueDate!),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        locale: const Locale('es', 'ES'),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDueDate = picked);
                      }
                    },
                  ),
                ),
                if (selectedDueDate != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          setDialogState(() => selectedDueDate = null),
                      child: const Text('Quitar vencimiento'),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: selectedSeason,
                  decoration: const InputDecoration(labelText: 'Temporada'),
                  items: seasons
                      .map(
                        (season) => DropdownMenuItem(
                          value: season,
                          child: Text(season),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedSeason = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || widget.teamId == null) {
      conceptController.dispose();
      amountController.dispose();
      return;
    }

    final concept = conceptController.text.trim();
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    conceptController.dispose();
    amountController.dispose();

    if (amount == null || amount <= 0) {
      _showSnack('Monto inválido');
      return;
    }

    try {
      final result = await _financeService.generateFeeBatch(
        teamId: widget.teamId!,
        concept: concept,
        amount: amount,
        dueDate: selectedDueDate == null
            ? null
            : _formatDate(selectedDueDate!),
        season: selectedSeason,
      );
      _showSnack('Se generaron ${result['created']} cuotas');
      await reload();
    } catch (e) {
      _showSnack(FinanceService.errorMessage(e));
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _showRegisterPaymentDialog(PlayerBalance? preselected) async {
    PlayerBalance? selected = preselected ??
        (_balances.isNotEmpty ? _balances.first : null);
    final amountController = TextEditingController();
    String method = 'transfer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PlayerBalance>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Jugador'),
                  items: _balances
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => selected = value),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto'),
                ),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Método'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
                    DropdownMenuItem(value: 'mercadopago', child: Text('Mercado Pago')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => method = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || widget.teamId == null || selected == null) return;

    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showSnack('Monto inválido');
      return;
    }

    try {
      await _financeService.registerPayment(
        teamId: widget.teamId!,
        userId: selected!.userId,
        amount: amount,
        method: method,
      );
      _showSnack('Pago registrado');
      await reload();
    } catch (e) {
      _showSnack(FinanceService.errorMessage(e));
    }
  }

  Future<void> _showExpenseDialog() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.teamId == null) return;

    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      _showSnack('Monto inválido');
      return;
    }

    try {
      await _financeService.createTeamExpense(
        teamId: widget.teamId!,
        amount: amount,
        description: descriptionController.text.trim(),
      );
      _showSnack('Gasto registrado');
      await reload();
    } catch (e) {
      _showSnack(FinanceService.errorMessage(e));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

    final summary = _summary!;

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Caja',
                  value: formatMoney(summary.cashBalance),
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Por cobrar',
                  value: formatMoney(summary.totalOutstanding),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Ingresos',
                  value: formatMoney(summary.totalIncome),
                  icon: Icons.arrow_downward,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Egresos',
                  value: formatMoney(summary.totalExpenses),
                  icon: Icons.arrow_upward,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_pendingPayments.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Pagos pendientes de confirmación',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${_pendingPayments.length}'),
                  backgroundColor: Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._pendingPayments.map(
              (payment) => Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.userName ?? 'Jugador #${payment.userId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatMoney(payment.amount)} · '
                        '${paymentMethodLabel(payment.method)}',
                      ),
                      if (payment.notes != null && payment.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            payment.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (payment.hasReceipt) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => PaymentReceiptDialog.show(
                              context,
                              paymentId: payment.id,
                              mimeType: payment.receiptMimeType,
                            ),
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Ver comprobante'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _confirmPayment(payment),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Confirmar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _rejectPayment(payment),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Rechazar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _showGenerateFeesDialog,
                icon: const Icon(Icons.receipt),
                label: const Text('Generar cuotas'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showRegisterPaymentDialog(null),
                icon: const Icon(Icons.payments),
                label: const Text('Registrar pago'),
              ),
              OutlinedButton.icon(
                onPressed: _showExpenseDialog,
                icon: const Icon(Icons.money_off),
                label: const Text('Gasto'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Saldos por jugador',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_balances.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No hay jugadores en la lista de buena fe'),
              ),
            )
          else
            ..._balances.map(
              (balance) => Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        child: Text(balance.userName.isNotEmpty
                            ? balance.userName[0].toUpperCase()
                            : '?'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balance.jerseyNumber != null
                                  ? '${balance.userName} #${balance.jerseyNumber}'
                                  : balance.userName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cargado ${formatMoney(balance.totalCharged)} · '
                              'Pagado ${formatMoney(balance.totalPaid)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(balance.balance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balance.balance > 0
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showRegisterPaymentDialog(balance),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Cobrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

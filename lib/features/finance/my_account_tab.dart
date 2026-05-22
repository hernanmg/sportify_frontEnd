import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/models/finance.dart';

class MyAccountTab extends StatefulWidget {
  final int? teamId;

  const MyAccountTab({super.key, required this.teamId});

  @override
  State<MyAccountTab> createState() => MyAccountTabState();
}

class MyAccountTabState extends State<MyAccountTab> {
  final FinanceService _financeService = FinanceService();
  MyAccountSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant MyAccountTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      reload();
    }
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _financeService.getMyAccount(teamId: widget.teamId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
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

  Future<void> _showSubmitPaymentDialog() async {
    if (widget.teamId == null) {
      _showSnack('Seleccioná un equipo primero');
      return;
    }

    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String method = 'transfer';
    XFile? receiptFile;
    String? receiptLabel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Informar pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'El manager deberá confirmar el pago antes de que se acredite en tu cuenta.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Monto'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Método'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(
                      value: 'mercadopago',
                      child: Text('Mercado Pago'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => method = value);
                  },
                ),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Referencia, CBU, etc.',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Galería'),
                              onTap: () =>
                                  Navigator.pop(ctx, ImageSource.gallery),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('Cámara'),
                              onTap: () =>
                                  Navigator.pop(ctx, ImageSource.camera),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (source == null) return;
                    final picked = await ImagePicker().pickImage(
                      source: source,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        receiptFile = picked;
                        receiptLabel = picked.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    receiptLabel ?? 'Adjuntar comprobante (opcional)',
                    overflow: TextOverflow.ellipsis,
                  ),
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
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      amountController.dispose();
      notesController.dispose();
      return;
    }

    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    final notes = notesController.text.trim();
    amountController.dispose();
    notesController.dispose();

    if (amount == null || amount <= 0) {
      _showSnack('Monto inválido');
      return;
    }

    try {
      await _financeService.submitPayment(
        teamId: widget.teamId!,
        amount: amount,
        method: method,
        notes: notes.isEmpty ? null : notes,
        receipt: receiptFile,
      );
      _showSnack(
        receiptFile != null
            ? 'Pago y comprobante enviados. Esperá confirmación del manager.'
            : 'Pago enviado. Esperando confirmación del manager.',
      );
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

  IconData _paymentIcon(String status) {
    switch (status) {
      case 'pending_confirmation':
        return Icons.hourglass_top;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.check_circle;
    }
  }

  Color _paymentColor(String status) {
    switch (status) {
      case 'pending_confirmation':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
    final pendingCharges = summary.charges
        .where((c) => c.status == 'pending' || c.status == 'partial')
        .toList();

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceCard(
            title: 'Saldo pendiente',
            amount: summary.balance,
            color: summary.balance > 0
                ? Colors.red.shade700
                : Colors.green.shade700,
          ),
          if (widget.teamId != null && summary.balance > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showSubmitPaymentDialog,
                icon: const Icon(Icons.send),
                label: const Text('Informar pago'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Cargado',
                  value: formatMoney(summary.totalCharged),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Pagado',
                  value: formatMoney(summary.totalPaid),
                ),
              ),
            ],
          ),
          if (summary.pendingPayments.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Pagos en revisión',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...summary.pendingPayments.map(
              (payment) => Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(Icons.hourglass_top, color: Colors.orange.shade800),
                  title: Text(formatMoney(payment.amount)),
                  subtitle: Text(
                    '${paymentMethodLabel(payment.method)} · ${payment.createdAt ?? ''}',
                  ),
                  trailing: Chip(
                    label: Text(
                      payment.statusLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Cargos pendientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (pendingCharges.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Estás al día'),
              ),
            )
          else
            ...pendingCharges.map(
              (charge) => Card(
                child: ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: charge.status == 'partial'
                        ? Colors.orange
                        : Colors.red,
                  ),
                  title: Text(charge.concept),
                  subtitle: Text(
                    'Vence: ${charge.dueDate ?? '—'} · ${charge.status}',
                  ),
                  trailing: Text(
                    formatMoney(charge.pendingAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Historial de pagos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (summary.payments.isEmpty)
            const Card(
              child: ListTile(title: Text('Sin pagos registrados')),
            )
          else
            ...summary.payments.take(15).map(
                  (payment) => Card(
                    child: ListTile(
                      leading: Icon(
                        _paymentIcon(payment.status),
                        color: _paymentColor(payment.status),
                      ),
                      title: Text(formatMoney(payment.amount)),
                      subtitle: Text(
                        [
                          paymentMethodLabel(payment.method),
                          payment.statusLabel,
                          if (payment.rejectionReason != null)
                            payment.rejectionReason!,
                          payment.createdAt ?? '',
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              formatMoney(amount),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

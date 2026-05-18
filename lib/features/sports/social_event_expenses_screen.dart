import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/event_expenses_service.dart';
import 'package:sportify_amateur/models/event_expense_sheet.dart';

class SocialEventExpensesScreen extends StatefulWidget {
  final int eventId;
  final String? eventTitle;

  const SocialEventExpensesScreen({
    super.key,
    required this.eventId,
    this.eventTitle,
  });

  @override
  State<SocialEventExpensesScreen> createState() =>
      _SocialEventExpensesScreenState();
}

class _SocialEventExpensesScreenState extends State<SocialEventExpensesScreen> {
  final EventExpensesService _service = EventExpensesService();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();

  EventExpenseSheetView? _view;
  bool _loading = true;
  String? _error;
  int? _currentUserId;
  int? _paidByUserId;
  bool _isManager = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final role = await AuthStorageService().getRole();
    final userIdStr = await AuthStorageService().getUserId();
    final userId = userIdStr != null ? int.tryParse(userIdStr) : null;

    setState(() {
      _isManager =
          role == 'manager' || role == 'super_admin' || role == 'admin';
      _currentUserId = userId;
      _paidByUserId = userId;
    });
    await _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final view = await _service.getSheet(widget.eventId);
      if (!mounted) return;
      setState(() {
        _view = view;
        _loading = false;
        if (_paidByUserId == null && view.participants.isNotEmpty) {
          final me = view.participants
              .where((p) => p.userId == _currentUserId && !p.isDeclined)
              .toList();
          _paidByUserId = me.isNotEmpty
              ? me.first.userId
              : view.participants.firstWhere((p) => !p.isDeclined).userId;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = EventExpensesService.errorMessage(e);
        _loading = false;
      });
    }
  }

  bool get _canAddExpense {
    final view = _view;
    if (view == null || _currentUserId == null) return false;
    return view.participants.any(
      (p) => p.userId == _currentUserId && !p.isDeclined,
    );
  }

  Future<void> _addExpense() async {
    final desc = _descController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (desc.isEmpty || amount == null || amount <= 0) {
      _snack('Ingresá descripción y monto válido');
      return;
    }
    if (_paidByUserId == null) {
      _snack('Seleccioná quién pagó');
      return;
    }

    setState(() => _submitting = true);
    try {
      final view = await _service.addItem(
        eventId: widget.eventId,
        description: desc,
        amount: amount,
        paidByUserId: _paidByUserId,
      );
      if (!mounted) return;
      _descController.clear();
      _amountController.clear();
      setState(() {
        _view = view;
        _submitting = false;
      });
      _snack('Gasto agregado');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _snack(EventExpensesService.errorMessage(e));
    }
  }

  Future<void> _deleteItem(EventExpenseItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${item.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final view = await _service.deleteItem(
        eventId: widget.eventId,
        itemId: item.id,
      );
      if (!mounted) return;
      setState(() => _view = view);
      _snack('Gasto eliminado');
    } catch (e) {
      _snack(EventExpensesService.errorMessage(e));
    }
  }

  bool _canDeleteItem(EventExpenseItem item) {
    if (_isManager) return true;
    if (_currentUserId == null) return false;
    return item.createdBy == _currentUserId ||
        item.paidByUserId == _currentUserId;
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _setSplitMode(String mode) async {
    try {
      final view = await _service.updateSplitMode(
        eventId: widget.eventId,
        splitMode: mode,
      );
      if (!mounted) return;
      setState(() => _view = view);
    } catch (e) {
      _snack(EventExpensesService.errorMessage(e));
    }
  }

  Future<void> _toggleInSplit(EventExpenseParticipantOption p, bool included) async {
    try {
      final view = await _service.setParticipantInSplit(
        eventId: widget.eventId,
        userId: p.userId,
        included: included,
      );
      if (!mounted) return;
      setState(() => _view = view);
    } catch (e) {
      _snack(EventExpensesService.errorMessage(e));
    }
  }

  Future<void> _saveManualShares() async {
    final view = _view!;
    final shares = view.balances
        .map((b) => {'userId': b.userId, 'amount': b.shareOwed})
        .toList();
    try {
      final updated = await _service.updateManualShares(
        eventId: widget.eventId,
        shares: shares,
      );
      if (!mounted) return;
      setState(() => _view = updated);
      _snack('Reparto manual guardado');
    } catch (e) {
      _snack(EventExpensesService.errorMessage(e));
    }
  }

  Future<void> _addGuestParticipant() async {
    List<Map<String, dynamic>> savedGuests = [];
    try {
      savedGuests = await _service.getSocialGuests(widget.eventId);
    } catch (_) {}

    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        return AlertDialog(
          title: const Text('Agregar persona al evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Alguien sin la app. Queda guardado para próximos eventos del equipo.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (savedGuests.isNotEmpty) ...[
                  const Text(
                    'Invitados guardados',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...savedGuests.map(
                    (g) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(g['displayName']?.toString() ?? ''),
                      subtitle: g['phone'] != null
                          ? Text(g['phone'].toString())
                          : null,
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () => Navigator.pop(ctx, {
                        'displayName': g['displayName']?.toString() ?? '',
                        if (g['phone'] != null) 'phone': g['phone'].toString(),
                      }),
                    ),
                  ),
                  const Divider(),
                ],
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y apellido *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx, {
                  'displayName': name,
                  if (phoneController.text.trim().isNotEmpty)
                    'phone': phoneController.text.trim(),
                });
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (result == null || (result['displayName'] ?? '').isEmpty) return;

    try {
      await _service.addSocialGuest(
        eventId: widget.eventId,
        displayName: result['displayName']!,
        phone: result['phone'],
      );
      await _reload();
      _snack('${result['displayName']} agregado al evento');
    } catch (e) {
      _snack(EventExpensesService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos del evento'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final view = _view!;
    final title = widget.eventTitle ?? view.eventTitle;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Cada participante suma lo que gastó. La app reparte el total entre los presentes y calcula quién le debe a quién.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          if (_isManager) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reparto', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'equal', label: Text('Igual')),
                        ButtonSegment(value: 'manual', label: Text('Manual')),
                      ],
                      selected: {view.splitMode},
                      onSelectionChanged: (s) => _setSplitMode(s.first),
                    ),
                    if (view.splitMode == 'manual') ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _saveManualShares,
                        child: const Text('Guardar reparto según montos actuales'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Presentes en el reparto'),
                    const Text(
                      'Solo quienes confirmaron asistencia pueden entrar en el reparto.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    ...view.participants.where((p) => !p.isDeclined).map(
                          (p) {
                            final canSplit = p.canToggleExpenseSplit;
                            return SwitchListTile(
                              dense: true,
                              title: Text(p.userName),
                              subtitle: Text(
                                canSplit
                                    ? 'Confirmado'
                                    : 'Pendiente — debe confirmar primero',
                              ),
                              value: canSplit && p.includedInExpenseSplit,
                              onChanged: canSplit
                                  ? (v) => _toggleInSplit(p, v)
                                  : null,
                            );
                          },
                        ),
                    OutlinedButton.icon(
                      onPressed: _addGuestParticipant,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Agregar persona (no del equipo)'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            color: Colors.deepPurple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total gastado', style: TextStyle(fontSize: 16)),
                  Text(
                    formatEventMoney(view.itemsTotal),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_canAddExpense) ...[
            const SizedBox(height: 20),
            Text('Sumar gasto', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Qué se compró / pagó',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      key: ValueKey(_paidByUserId),
                      initialValue: _paidByUserId,
                      decoration: const InputDecoration(
                        labelText: 'Quién pagó',
                        border: OutlineInputBorder(),
                      ),
                      items: view.participants
                          .where((p) => !p.isDeclined)
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.userId,
                              child: Text(p.userName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _paidByUserId = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _addExpense,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Agregar gasto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_currentUserId != null) ...[
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Para cargar gastos tenés que estar en la lista de participantes del evento (y no haber rechazado la invitación).'),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Gastos cargados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (view.items.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text('Todavía no hay gastos'),
                subtitle: Text('El primero en pagar algo puede sumarlo arriba.'),
              ),
            )
          else
            ...view.items.map(
              (item) => Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.payments)),
                  title: Text(item.description),
                  subtitle: Text('Pagó: ${item.paidByName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatEventMoney(item.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_canDeleteItem(item))
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteItem(item),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text('Cuenta por persona', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Positivo = le deben plata · Negativo = debe pagar',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...view.balances.map(
            (b) => Card(
              child: ListTile(
                title: Text(b.userName),
                subtitle: Text(
                  'Pagó ${formatEventMoney(b.totalPaid)} · Su parte ${formatEventMoney(b.shareOwed)}',
                ),
                trailing: Text(
                  formatEventMoney(b.netBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: b.isCreditor
                        ? Colors.green.shade700
                        : b.isDebtor
                            ? Colors.red.shade700
                            : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Liquidación sugerida', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (view.settlements.isEmpty)
            const Text('Cuando haya gastos, aparecerán las transferencias sugeridas.')
          else
            ...view.settlements.map(
              (s) => Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text('${s.fromUserName} → ${s.toUserName}'),
                  trailing: Text(
                    formatEventMoney(s.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

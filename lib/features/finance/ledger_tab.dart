import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/models/finance.dart';

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
      final entries =
          await _financeService.getTeamLedger(widget.teamId!, limit: 100);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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

    if (_entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Sin movimientos en la caja')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final isIncome = entry.isIncome;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isIncome
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.red.withValues(alpha: 0.15),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(entry.description),
              subtitle: Text('${entry.category} · ${entry.createdAt ?? ''}'),
              trailing: Text(
                '${isIncome ? '+' : '-'}${formatMoney(entry.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

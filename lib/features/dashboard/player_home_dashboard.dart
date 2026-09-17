import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/active_workspace_provider.dart';
import 'package:sportify_amateur/core/services/finance_service.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:sportify_amateur/features/sports/event_detail_screen.dart';
import 'package:sportify_amateur/models/finance.dart';
import 'package:sportify_amateur/models/sport_event.dart';

/// Resumen “qué tengo hoy” para jugador: próximo evento, convocatoria y cuota.
class PlayerHomeDashboard extends StatefulWidget {
  const PlayerHomeDashboard({super.key});

  @override
  State<PlayerHomeDashboard> createState() => _PlayerHomeDashboardState();
}

class _PlayerHomeDashboardState extends State<PlayerHomeDashboard> {
  final _eventsService = SportEventsService();
  final _financeService = FinanceService();

  List<SportEvent> _upcoming = [];
  MyAccountSummary? _account;
  bool _loading = true;
  String? _error;
  bool _responding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  DateTime get _startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final teamId = context.read<ActiveWorkspaceProvider>().teamId;
      final results = await Future.wait([
        _eventsService.getMyEvents(),
        _financeService.getMyAccount(teamId: teamId),
      ]);
      final events = results[0] as List<SportEvent>;
      final account = results[1] as MyAccountSummary;

      final upcoming = events
          .where((e) =>
              !e.eventDate.isBefore(_startOfToday) &&
              e.status != SportEventStatus.cancelled)
          .toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      if (!mounted) return;
      setState(() {
        _upcoming = upcoming;
        _account = account;
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

  bool _isPending(SportEvent e) {
    final s = e.myParticipationStatus;
    return s == null || s == 'pending' || s == 'no_response';
  }

  SportEvent? get _nextEvent => _upcoming.isEmpty ? null : _upcoming.first;

  List<SportEvent> get _pendingOthers {
    final next = _nextEvent;
    return _upcoming
        .where((e) => _isPending(e) && (next == null || e.id != next.id))
        .take(2)
        .toList();
  }

  FeeCharge? get _openCharge {
    final charges = _account?.charges ?? const <FeeCharge>[];
    final open = charges
        .where((c) =>
            c.status != 'paid' &&
            c.status != 'waived' &&
            c.pendingAmount > 0.009)
        .toList();
    if (open.isEmpty) return null;
    open.sort((a, b) {
      final ad = a.dueDate ?? '';
      final bd = b.dueDate ?? '';
      return ad.compareTo(bd);
    });
    return open.first;
  }

  String _typeLabel(SportEventType type) {
    switch (type) {
      case SportEventType.match:
        return 'Partido';
      case SportEventType.training:
        return 'Entrenamiento';
      case SportEventType.social:
        return 'Social';
      case SportEventType.meeting:
        return 'Reunión';
    }
  }

  IconData _typeIcon(SportEventType type) {
    switch (type) {
      case SportEventType.match:
        return Icons.sports_soccer;
      case SportEventType.training:
        return Icons.fitness_center;
      case SportEventType.social:
        return Icons.celebration;
      case SportEventType.meeting:
        return Icons.groups;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'declined':
        return 'No voy';
      case 'pending':
      case 'no_response':
      case null:
        return 'Pendiente de respuesta';
      default:
        return status ?? 'Pendiente';
    }
  }

  Future<void> _respond(SportEvent event, String status) async {
    if (_responding) return;
    setState(() => _responding = true);
    try {
      if (status == 'confirmed') {
        await _eventsService.confirmParticipation(event.id);
      } else {
        await _eventsService.declineParticipation(event.id);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'confirmed' ? 'Asistencia confirmada' : 'Respuesta enviada',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  void _openEvent(SportEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(event: event),
      ),
    ).then((_) => _load());
  }

  void _openFinances() {
    AppShellScope.maybeOf(context)?.selectTab(1);
  }

  void _openMyEvents() {
    AppShellScope.maybeOf(context)?.selectTab(3);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: const Text('No se pudo cargar tu estado'),
          subtitle: Text(_error!, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ),
      );
    }

    final dateFmt = DateFormat('EEE d/M · HH:mm', 'es');
    final next = _nextEvent;
    final charge = _openCharge;
    final balance = _account?.balance ?? 0;
    final owes = balance > 0.009;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Qué tenés hoy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 10),
              _StatusTile(
                icon: _typeIcon(next.type),
                title: next.title,
                subtitle: [
                  _typeLabel(next.type),
                  if (next.opponentName != null &&
                      next.opponentName!.trim().isNotEmpty)
                    'vs ${next.opponentName}',
                  dateFmt.format(next.eventDate),
                ].join(' · '),
                trailing: _statusLabel(next.myParticipationStatus),
                trailingColor: _isPending(next)
                    ? Colors.orange.shade800
                    : next.myParticipationStatus == 'confirmed'
                        ? Colors.green.shade700
                        : null,
                onTap: () => _openEvent(next),
              ),
              if (_isPending(next)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _responding
                            ? null
                            : () => _respond(next, 'declined'),
                        child: const Text('No voy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _responding
                            ? null
                            : () => _respond(next, 'confirmed'),
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              const SizedBox(height: 10),
              _StatusTile(
                icon: Icons.event_available_outlined,
                title: 'Sin eventos próximos',
                subtitle: 'Cuando te convoquen o inviten, aparece acá',
                onTap: _openMyEvents,
              ),
            ],
            if (_pendingOthers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Otras pendientes',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ..._pendingOthers.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _StatusTile(
                    icon: Icons.hourglass_top,
                    title: e.title,
                    subtitle: dateFmt.format(e.eventDate),
                    trailing: 'Responder',
                    trailingColor: Colors.orange.shade800,
                    onTap: () => _openEvent(e),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _StatusTile(
              icon: owes
                  ? Icons.warning_amber_rounded
                  : Icons.account_balance_wallet_outlined,
              iconColor: owes ? Colors.orange.shade800 : Colors.green.shade700,
              title: owes ? 'Tu cuota' : 'Cuenta al día',
              subtitle: charge != null && owes
                  ? '${charge.concept}${charge.periodLabel != null ? ' · ${charge.periodLabel}' : ''}'
                  : owes
                      ? 'Tenés saldo pendiente con el equipo'
                      : 'Sin cuotas pendientes',
              trailing: '\$${balance.abs().toStringAsFixed(0)}',
              trailingColor: owes ? Colors.orange.shade800 : Colors.green.shade700,
              onTap: _openFinances,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event_available, size: 18),
                  label: const Text('Mis eventos'),
                  onPressed: _openMyEvents,
                ),
                ActionChip(
                  avatar: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Mi cuenta'),
                  onPressed: _openFinances,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.trailing,
    this.trailingColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: trailingColor,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

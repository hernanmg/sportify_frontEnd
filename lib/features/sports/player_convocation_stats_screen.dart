import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/convocations_service.dart';
import 'package:sportify_amateur/models/player_convocation_stats.dart';

class PlayerConvocationStatsScreen extends StatefulWidget {
  final int teamId;
  final int userId;
  final String playerName;

  const PlayerConvocationStatsScreen({
    super.key,
    required this.teamId,
    required this.userId,
    required this.playerName,
  });

  @override
  State<PlayerConvocationStatsScreen> createState() =>
      _PlayerConvocationStatsScreenState();
}

class _PlayerConvocationStatsScreenState
    extends State<PlayerConvocationStatsScreen> {
  final _service = ConvocationsService();
  PlayerConvocationStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _service.getPlayerHistory(
        teamId: widget.teamId,
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial · ${widget.playerName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Sin datos'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _statCard(
                        'Convocado',
                        '${_stats!.timesConvoked}',
                        Icons.sports_soccer,
                      ),
                      _statCard(
                        'Confirmó',
                        '${_stats!.confirmed} (${_stats!.confirmationRate}%)',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _statCard(
                        'Rechazó',
                        '${_stats!.declined}',
                        Icons.cancel,
                        Colors.red,
                      ),
                      _statCard(
                        'Pendiente',
                        '${_stats!.pending}',
                        Icons.hourglass_empty,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Partidos recientes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._stats!.recent.map((r) {
                        final date = r.eventDate != null
                            ? DateFormat('dd/MM/yy').format(r.eventDate!)
                            : '';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              r.isConvoked
                                  ? Icons.check
                                  : Icons.remove_circle_outline,
                            ),
                            title: Text(r.title),
                            subtitle: Text(
                              '${r.opponentName ?? ''} · $date · ${r.statusLabel}',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

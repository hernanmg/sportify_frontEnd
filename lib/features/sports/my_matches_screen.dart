import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/convocations_service.dart';
import 'package:sportify_amateur/features/sports/post_match_screen.dart';
import 'package:sportify_amateur/models/sport_event.dart';

/// Partidos del jugador (convocado) con acceso a votación post-partido.
class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  final _service = ConvocationsService();
  List<SportEvent> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getMyConvocations();
      if (!mounted) return;
      setState(() {
        _matches = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis partidos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _matches.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No tenés convocatorias')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _matches.length,
                      itemBuilder: (_, i) {
                        final m = _matches[i];
                        final dateStr =
                            DateFormat('dd/MM/yyyy HH:mm').format(m.eventDate);
                        final canPost = canOpenPostMatch(m);
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              m.isOfficialMatch
                                  ? Icons.emoji_events
                                  : Icons.sports_soccer,
                              color: Colors.green,
                            ),
                            title: Text(m.title),
                            subtitle: Text(
                              '${m.opponentName ?? 'Rival'} · $dateStr',
                            ),
                            trailing: canPost
                                ? const Icon(Icons.how_to_vote)
                                : null,
                            onTap: canPost
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PostMatchScreen(
                                          eventId: m.id,
                                          eventTitle: m.title,
                                        ),
                                      ),
                                    );
                                    if (mounted) await _load();
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

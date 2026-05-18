import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';

/// Muestra / genera código de invitación para admins del equipo.
class TeamInviteScreen extends StatefulWidget {
  final MyTeamOption team;

  const TeamInviteScreen({super.key, required this.team});

  @override
  State<TeamInviteScreen> createState() => _TeamInviteScreenState();
}

class _TeamInviteScreenState extends State<TeamInviteScreen> {
  final _teamService = TeamService();
  String? _code;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final result = await _teamService.createTeamInvite(
        widget.team.teamId,
        categoryIds: widget.team.categoryIds.isNotEmpty
            ? widget.team.categoryIds
            : null,
      );
      setState(() => _code = result['code']?.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TeamService.errorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copy() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitar — ${widget.team.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Compartí este código por WhatsApp o en persona. Quien se registre y lo ingrese quedará en tu equipo.',
            ),
            const SizedBox(height: 32),
            if (_code != null) ...[
              SelectableText(
                _code!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código'),
              ),
            ] else
              ElevatedButton(
                onPressed: _loading ? null : _generate,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Generar código de invitación'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/features/teams/join_team_screen.dart';

/// Pantalla corta para DT / admin que ya tienen cuenta pero aún no están en un equipo.
class StaffTeamSetupScreen extends StatefulWidget {
  const StaffTeamSetupScreen({super.key});

  @override
  State<StaffTeamSetupScreen> createState() => _StaffTeamSetupScreenState();
}

class _StaffTeamSetupScreenState extends State<StaffTeamSetupScreen> {
  String _role = 'dt';
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final storage = AuthStorageService();
    final role = await storage.getRole();
    final name = await storage.getUserName();
    if (!mounted) return;
    setState(() {
      _role = role ?? 'dt';
      _displayName = name;
    });
  }

  String get _roleLabel {
    switch (_role) {
      case 'super_admin':
        return 'Super administrador';
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Encargado';
      case 'dt':
      default:
        return 'Director técnico';
    }
  }

  Future<void> _openJoin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const JoinTeamScreen()),
    );
    if (ok == true && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _displayName?.trim().isNotEmpty == true
        ? 'Hola, $_displayName'
        : 'Hola';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.sports_soccer, size: 64, color: Colors.green.shade700),
              const SizedBox(height: 16),
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(_roleLabel),
                avatar: const Icon(Icons.verified_user, size: 18),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu cuenta ya está identificada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Como $_roleLabel, unite al equipo que creó el administrador '
                        'con el código de invitación que te comparta. '
                        'También podés crear un equipo nuevo más adelante desde Gestión de equipos.',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _openJoin,
                icon: const Icon(Icons.vpn_key),
                label: const Text('Tengo un código de invitación'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/dashboard'),
                child: const Text('Ir al inicio y configurar después'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

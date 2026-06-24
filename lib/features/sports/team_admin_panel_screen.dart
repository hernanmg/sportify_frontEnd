import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sportify_amateur/core/services/team_admin_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/features/sports/attendance_screen.dart';
import 'package:sportify_amateur/features/sports/event_attendance_screen.dart';
import 'package:sportify_amateur/features/finance/quota_overview_screen.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/features/sports/event_detail_screen.dart';
import 'package:sportify_amateur/models/finance.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/features/teams/team_form_screen.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/team.dart';

class TeamAdminPanelScreen extends StatefulWidget {
  final int? initialTeamId;

  const TeamAdminPanelScreen({super.key, this.initialTeamId});

  @override
  State<TeamAdminPanelScreen> createState() => _TeamAdminPanelScreenState();
}

class _TeamAdminPanelScreenState extends State<TeamAdminPanelScreen> {
  final _service = TeamAdminService();
  final _teamService = TeamService();
  final _eventsService = SportEventsService();

  List<MyTeamOption> _teams = [];
  MyTeamOption? _selected;
  TeamAdminPanel? _panel;
  Team? _team;
  List<Map<String, dynamic>> _members = [];
  int? _birthdayHour;
  bool _savingBirthdayHour = false;
  bool _loading = true;
  String? _error;
  bool _isPlatformAdmin = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final role = await AuthStorageService().getRole();
      _userRole = role;
      _isPlatformAdmin =
          role == 'super_admin' || role == 'manager' || role == 'admin';
      var teams = await _teamService.getMyTeams();
      teams = MyTeamOption.dedupeByTeamId(teams);
      final selected = widget.initialTeamId != null
          ? MyTeamOption.findInList(teams, widget.initialTeamId!)
          : (teams.isNotEmpty ? teams.first : null);
      setState(() {
        _teams = teams;
        _selected = selected;
      });
      if (selected != null) await _load(selected.teamId);
    } catch (e) {
      setState(() {
        _error = TeamAdminService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _load(int teamId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final panel = await _service.getAdminPanel(teamId);
      final team = await _teamService.getTeamById(teamId);
      List<Map<String, dynamic>> members = [];
      try {
        members = await _teamService.listTeamMembers(teamId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _panel = panel;
        _team = team;
        _members = members;
        _birthdayHour = team.birthdayNotificationHour;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = TeamAdminService.errorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del equipo (DT)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selected == null
                ? null
                : () => _load(_selected!.teamId),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_teams.isEmpty && !_loading) {
      return const Center(child: Text('No tenés equipos asignados'));
    }

    return Column(
      children: [
        if (_teams.length > 1)
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<MyTeamOption>(
              value: _selected,
              decoration: const InputDecoration(
                labelText: 'Equipo',
                border: OutlineInputBorder(),
              ),
              items: _teams
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.listLabel(_teams)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selected = v);
                _load(v.teamId);
              },
            ),
          ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final panel = _panel;
    if (panel == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _load(panel.teamId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _quickActions(panel.teamId),
          const SizedBox(height: 16),
          _birthdaySettingsCard(panel.teamId),
          const SizedBox(height: 16),
          _sectionTitle('Finanzas del mes'),
          _financeCard(panel.monthFinance),
          const SizedBox(height: 16),
          _sectionTitle('Morosos (${panel.debtors.length})'),
          if (panel.debtors.isEmpty)
            const Text('Todos al día en cuotas visibles')
          else
            ...panel.debtors.map(
              (d) => ListTile(
                dense: true,
                title: Text(d.userName),
                trailing: Text(
                  formatMoney(d.balance),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _sectionTitle('Confirmaciones pendientes'),
          if (panel.pendingConfirmations.isEmpty)
            const Text('Sin pendientes en próximos eventos')
          else
            ...panel.pendingConfirmations.map(_pendingCard),
          const SizedBox(height: 16),
          _sectionTitle('Última sesión — asistencia'),
          if (panel.lastSessionAttendance == null)
            const Text('Sin sesiones pasadas registradas')
          else
            _lastSessionCard(panel.lastSessionAttendance!),
          const SizedBox(height: 16),
          _sectionTitle('Roles de finanzas'),
          _teamRolesCard(panel.teamId),
        ],
      ),
    );
  }

  Widget _teamRolesCard(int teamId) {
    if (_members.isEmpty) {
      return const Text('Sin miembros cargados');
    }
    const roleLabels = {
      'admin': 'Admin equipo',
      'treasurer': 'Tesorero',
      'delegate': 'Delegado',
      'player': 'Jugador',
    };
    return Card(
      child: Column(
        children: _members.map((m) {
          final userId = m['userId'] as int;
          final role = m['role']?.toString() ?? 'player';
          return ListTile(
            dense: true,
            title: Text(m['userName']?.toString() ?? 'Usuario $userId'),
            subtitle: const Text(
              'Tesorero/delegado pueden gestionar cuotas y caja',
              style: TextStyle(fontSize: 11),
            ),
            trailing: DropdownButton<String>(
              value: role,
              underline: const SizedBox.shrink(),
              items: roleLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (newRole) async {
                if (newRole == null || newRole == role) return;
                try {
                  await _teamService.updateTeamMemberRole(
                    teamId,
                    userId,
                    newRole,
                  );
                  await _load(teamId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rol actualizado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(TeamService.errorMessage(e))),
                  );
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _birthdaySettingsCard(int teamId) {
    final hour = _birthdayHour ?? 9;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake_outlined, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Avisos de cumpleaños',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cada día, a la hora elegida, el plantel recibe un aviso si alguien cumple años. El cumpleañero recibe un mensaje especial del equipo.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: hour,
              decoration: const InputDecoration(
                labelText: 'Hora de envío (Argentina)',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                24,
                (h) => DropdownMenuItem(
                  value: h,
                  child: Text('${h.toString().padLeft(2, '0')}:00'),
                ),
              ),
              onChanged: _savingBirthdayHour
                  ? null
                  : (v) => setState(() => _birthdayHour = v ?? hour),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _savingBirthdayHour || _birthdayHour == null
                    ? null
                    : () => _saveBirthdayHour(teamId),
                icon: _savingBirthdayHour
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar hora'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBirthdayHour(int teamId) async {
    final hour = _birthdayHour;
    if (hour == null) return;
    setState(() => _savingBirthdayHour = true);
    try {
      final team =
          await _teamService.updateBirthdayNotificationHour(teamId, hour);
      if (!mounted) return;
      setState(() {
        _team = team;
        _birthdayHour = team.birthdayNotificationHour;
        _savingBirthdayHour = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hora de cumpleaños actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingBirthdayHour = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TeamAdminService.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editTeam(int teamId) async {
    try {
      final team = await _teamService.getTeamById(teamId);
      if (!mounted) return;
      final updated = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeamFormScreen(team: team)),
      );
      if (updated != null) await _load(teamId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TeamService.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _quickActions(int teamId) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (UserCapabilities.canManageTeamSettings(_userRole))
          ActionChip(
            avatar: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar equipo'),
            onPressed: () => _editTeam(teamId),
          ),
        ActionChip(
          avatar: const Icon(Icons.payments, size: 18),
          label: const Text('Cuotas del equipo'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuotaOverviewScreen(teamId: teamId),
            ),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.fact_check, size: 18),
          label: const Text('Asistencias'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceScreen(teamId: teamId),
            ),
          ),
        ),
        if (_isPlatformAdmin)
          ActionChip(
            avatar: const Icon(Icons.groups_3, size: 18),
            label: const Text('Gestión de equipos'),
            onPressed: () => Navigator.pushNamed(context, '/teams'),
          ),
      ],
    );
  }

  Widget _financeCard(MonthFinance f) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Ingresos', formatMoney(f.income), Colors.green),
                _stat('Gastos', formatMoney(f.expenses), Colors.red),
                _stat('Mes', formatMoney(f.net), Colors.blue),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Saldo caja: ${formatMoney(f.cashBalance)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _pendingCard(PendingConfirmationEvent e) {
    final dateStr = DateFormat('dd/MM HH:mm').format(e.eventDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${e.title} ($dateStr)'),
        subtitle: Text(
          '${e.pendingCount} sin confirmar · ${e.type}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openPendingEvent(e),
      ),
    );
  }

  Future<void> _openPendingEvent(PendingConfirmationEvent e) async {
    try {
      final event = await _eventsService.getEventById(e.eventId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(event: event),
        ),
      );
      if (_selected != null) await _load(_selected!.teamId);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el evento: $err'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _lastSessionCard(LastSessionAttendance s) {
    final dateStr = DateFormat('dd/MM/yyyy').format(s.eventDate);
    return Card(
      child: ListTile(
        title: Text('${s.title} · $dateStr'),
        subtitle: Text(
          'Presentes ${s.present} · Ausentes ${s.absent} · '
          'Justificados ${s.justified} · Sin marcar ${s.unmarked}',
        ),
        trailing: const Icon(Icons.edit_calendar),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventAttendanceScreen(eventId: s.eventId),
            ),
          ).then((_) {
            if (_selected != null) _load(_selected!.teamId);
          });
        },
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

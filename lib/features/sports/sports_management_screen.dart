import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/sports/roster_management_screen.dart';
import 'package:sportify_amateur/features/sports/events_management_screen.dart';
import 'package:sportify_amateur/features/sports/convocations_screen.dart';
import 'package:sportify_amateur/features/sports/player_status_screen.dart';
import 'package:sportify_amateur/features/sports/convocation_form_screen.dart';
import 'package:sportify_amateur/features/sports/event_form_screen.dart';
import 'package:sportify_amateur/features/sports/roster_form_improved_screen.dart';
import 'package:sportify_amateur/features/teams/join_team_screen.dart';
import 'package:sportify_amateur/features/teams/team_invite_screen.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/models/sport_event.dart';
import 'package:sportify_amateur/features/sports/team_admin_panel_screen.dart';
import 'package:sportify_amateur/features/finance/quota_overview_screen.dart';
import 'package:sportify_amateur/features/sports/attendance_screen.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/features/shell/app_shell_scope.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/features/sports/team_calendar_screen.dart';
import 'package:sportify_amateur/widgets/season_selector_chip.dart';

enum _SportsMgmtTab { roster, events, convocations, playerStatus }

class SportsManagementScreen extends StatefulWidget {
  final int initialTabIndex;
  final int? initialTeamId;

  const SportsManagementScreen({
    Key? key,
    this.initialTabIndex = 0,
    this.initialTeamId,
  }) : super(key: key);

  @override
  _SportsManagementScreenState createState() => _SportsManagementScreenState();
}

class _SportsManagementScreenState extends State<SportsManagementScreen> {
  final NotificationService _notificationService = NotificationService();
  final GlobalKey<RosterManagementScreenState> _rosterListKey =
      GlobalKey<RosterManagementScreenState>();
  final GlobalKey<ConvocationsScreenState> _convocationsKey =
      GlobalKey<ConvocationsScreenState>();
  final GlobalKey<EventsManagementScreenState> _eventsKey =
      GlobalKey<EventsManagementScreenState>();
  final GlobalKey<PlayerStatusScreenState> _playerStatusKey =
      GlobalKey<PlayerStatusScreenState>();

  String? _userRole;
  bool _roleReady = false;
  List<_SportsMgmtTab> _visibleTabs = [_SportsMgmtTab.roster];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  List<_SportsMgmtTab> _tabsForRole(String? role) {
    final tabs = <_SportsMgmtTab>[_SportsMgmtTab.roster];
    if (UserCapabilities.canManageSportsEvents(role)) {
      tabs.addAll([
        _SportsMgmtTab.events,
        _SportsMgmtTab.convocations,
        _SportsMgmtTab.playerStatus,
      ]);
    }
    return tabs;
  }

  int _initialTabIndexFor(List<_SportsMgmtTab> tabs) {
    final requested =
        _SportsMgmtTab.values[widget.initialTabIndex.clamp(0, 3)];
    final idx = tabs.indexOf(requested);
    return idx >= 0 ? idx : 0;
  }

  Future<void> _loadRole() async {
    final role = await AuthStorageService().getRole();
    if (!mounted) return;
    final tabs = _tabsForRole(role);
    setState(() {
      _userRole = role;
      _visibleTabs = tabs;
      _selectedTabIndex =
          _initialTabIndexFor(tabs).clamp(0, tabs.length - 1);
      _roleReady = true;
    });
  }

  bool get _isStaff => UserCapabilities.isStaff(_userRole);

  bool get _isPlatformAdmin => UserCapabilities.isPlatformAdmin(_userRole);

  _SportsMgmtTab? get _currentTab {
    if (_selectedTabIndex < 0 || _selectedTabIndex >= _visibleTabs.length) {
      return null;
    }
    return _visibleTabs[_selectedTabIndex];
  }

  ({IconData icon, String label}) _tabMeta(_SportsMgmtTab tab) {
    switch (tab) {
      case _SportsMgmtTab.roster:
        return (icon: Icons.list_alt, label: 'Lista de Buena Fe');
      case _SportsMgmtTab.events:
        return (icon: Icons.event, label: 'Eventos');
      case _SportsMgmtTab.convocations:
        return (icon: Icons.sports_soccer, label: 'Convocatorias');
      case _SportsMgmtTab.playerStatus:
        return (icon: Icons.health_and_safety, label: 'Estado Jugadores');
    }
  }

  Widget _buildTabSelector() {
    if (_visibleTabs.length <= 1) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: _visibleTabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final meta = _tabMeta(tab);
            final selected = _selectedTabIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                avatar: Icon(
                  meta.icon,
                  size: 18,
                  color: selected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : null,
                ),
                label: Text(meta.label),
                selected: selected,
                onSelected: (_) {
                  setState(() => _selectedTabIndex = index);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión deportiva'),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          const SeasonSelectorChip(),
          if (_roleReady)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => _buildOverflowMenuItems(),
            ),
        ],
      ),
      body: !_roleReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabSelector(),
                _buildOperationsBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: _visibleTabs.map(_buildTabBody).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: !_roleReady
          ? null
          : () {
              final fab = _buildFloatingActionButton();
              if (fab == null) return null;
              return Padding(
                padding: const EdgeInsets.only(bottom: kAppShellBottomInset),
                child: fab,
              );
            }(),
    );
  }

  Widget _buildTabBody(_SportsMgmtTab tab) {
    switch (tab) {
      case _SportsMgmtTab.roster:
        return RosterManagementScreen(
          key: _rosterListKey,
          teamId: widget.initialTeamId,
        );
      case _SportsMgmtTab.events:
        return EventsManagementScreen(key: _eventsKey);
      case _SportsMgmtTab.convocations:
        return ConvocationsScreen(key: _convocationsKey);
      case _SportsMgmtTab.playerStatus:
        return PlayerStatusScreen(
          key: _playerStatusKey,
          initialTeamId: widget.initialTeamId,
        );
    }
  }

  List<PopupMenuEntry<String>> _buildOverflowMenuItems() {
    final items = <PopupMenuEntry<String>>[];
    if (_isStaff) {
      items.addAll(const [
        PopupMenuItem(
          value: 'admin_panel',
          child: ListTile(
            leading: Icon(Icons.dashboard_customize),
            title: Text('Panel del equipo'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'attendance',
          child: ListTile(
            leading: Icon(Icons.fact_check),
            title: Text('Asistencias'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'send_training_reminder',
          child: ListTile(
            leading: Icon(Icons.fitness_center),
            title: Text('Recordatorio Entrenamiento'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'send_payment_reminder',
          child: ListTile(
            leading: Icon(Icons.payment),
            title: Text('Recordatorio Pago'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'medical_alerts',
          child: ListTile(
            leading: Icon(Icons.medical_services),
            title: Text('Alertas Médicas'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ]);
    }
    items.add(const PopupMenuItem(
      value: 'team_quotas',
      child: ListTile(
        leading: Icon(Icons.groups),
        title: Text('Cuotas del plantel'),
        contentPadding: EdgeInsets.zero,
      ),
    ));
    if (UserCapabilities.canOnlyCreateSocialEvents(_userRole)) {
      items.add(const PopupMenuItem(
        value: 'create_social_event',
        child: ListTile(
          leading: Icon(Icons.celebration),
          title: Text('Crear evento social'),
          contentPadding: EdgeInsets.zero,
        ),
      ));
    } else {
      items.add(const PopupMenuItem(
        value: 'social_event',
        child: ListTile(
          leading: Icon(Icons.celebration),
          title: Text('Evento Social'),
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }
    items.add(const PopupMenuItem(
      value: 'calendar',
      child: ListTile(
        leading: Icon(Icons.calendar_month),
        title: Text('Calendario del equipo'),
        contentPadding: EdgeInsets.zero,
      ),
    ));
    if (_isPlatformAdmin) {
      items.add(const PopupMenuItem(
        value: 'manage_teams',
        child: ListTile(
          leading: Icon(Icons.groups_3),
          title: Text('Crear / gestionar equipos'),
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }
    if (!_isPlatformAdmin) {
      items.add(const PopupMenuItem(
        value: 'join_team',
        child: ListTile(
          leading: Icon(Icons.vpn_key),
          title: Text('Unirme con código'),
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }
    if (UserCapabilities.canInviteToTeam(_userRole)) {
      items.add(const PopupMenuItem(
        value: 'invite_team',
        child: ListTile(
          leading: Icon(Icons.share),
          title: Text('Invitar al equipo'),
          contentPadding: EdgeInsets.zero,
        ),
      ));
    }
    return items;
  }

  Widget _buildOperationsBar() {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            if (_isStaff) ...[
              _opsChip(
                icon: Icons.dashboard_customize,
                label: 'Panel del equipo',
                tooltip:
                    'Morosos, confirmaciones, asistencia y saldo del mes (DT / admin)',
                onTap: _openAdminPanel,
              ),
              _opsChip(
                icon: Icons.fact_check,
                label: 'Asistencias',
                onTap: _openAttendance,
              ),
            ],
            _opsChip(
              icon: Icons.groups,
              label: 'Cuotas plantel',
              onTap: _openTeamQuotas,
            ),
          ],
        ),
      ),
    );
  }

  Widget _opsChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip ?? label,
        child: ActionChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final tab = _currentTab;
    switch (tab) {
      case _SportsMgmtTab.roster:
        if (!UserCapabilities.canManageRoster(_userRole)) return null;
        return FloatingActionButton(
          onPressed: () => _addToRoster(),
          tooltip: 'Agregar Jugador',
          child: const Icon(Icons.person_add),
        );
      case _SportsMgmtTab.events:
        if (!UserCapabilities.canManageSportsEvents(_userRole)) return null;
        return FloatingActionButton(
          onPressed: () => _createStaffEvent(),
          tooltip: 'Crear Evento',
          child: const Icon(Icons.add_circle),
        );
      case _SportsMgmtTab.convocations:
        if (!UserCapabilities.canManageConvocations(_userRole)) return null;
        return FloatingActionButton(
          onPressed: () => _createConvocation(),
          tooltip: 'Nueva Convocatoria',
          child: const Icon(Icons.sports_soccer),
        );
      case _SportsMgmtTab.playerStatus:
      case null:
        return null;
    }
  }

  void _handleMenuAction(String action) async {
    try {
      switch (action) {
        case 'create_social_event':
          await _openSocialEventForm();
          break;
        case 'admin_panel':
          await _openAdminPanel();
          break;
        case 'team_quotas':
          await _openTeamQuotas();
          break;
        case 'attendance':
          await _openAttendance();
          break;
        case 'send_training_reminder':
          await _sendTrainingReminder();
          break;
        case 'send_payment_reminder':
          await _sendPaymentReminder();
          break;
        case 'medical_alerts':
          await _sendMedicalAlerts();
          break;
        case 'social_event':
          await _createSocialEvent();
          break;
        case 'calendar':
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => TeamCalendarScreen(
                initialTeamId: widget.initialTeamId,
              ),
            ),
          );
          break;
        case 'manage_teams':
          await Navigator.pushNamed(context, '/teams');
          break;
        case 'join_team':
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinTeamScreen()),
          );
          break;
        case 'invite_team':
          await _openTeamInvite();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendTrainingReminder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _TrainingReminderDialog(),
    );

    if (result != null) {
      try {
        await _notificationService.sendTrainingReminder(
          eventId: result['eventId'] ?? 1,
          teamId: result['teamId'] ?? 2,
          trainingDetails: {
            'date': result['date'],
            'location': result['location'],
            'duration': result['duration'],
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recordatorio de entrenamiento enviado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar recordatorio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendPaymentReminder() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PaymentReminderDialog(),
    );

    if (result != null) {
      try {
        await _notificationService.sendPaymentReminder(
          userIds: result['userIds'] ?? [1],
          teamId: result['teamId'] ?? 2,
          paymentDetails: {
            'amount': result['amount'],
            'dueDate': result['dueDate'],
            'concept': result['concept'],
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recordatorio de pago enviado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar recordatorio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendMedicalAlerts() async {
    try {
      await _notificationService.sendMedicalExpiryAlerts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alertas médicas enviadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar alertas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createSocialEvent() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SocialEventDialog(),
    );

    if (result != null) {
      try {
        await _notificationService.sendSocialEventNotification(
          eventId: result['eventId'] ?? 1,
          teamId: result['teamId'] ?? 2,
          eventDetails: {
            'title': result['title'],
            'date': result['date'],
            'location': result['location'],
            'hasExpenses': result['hasExpenses'] ?? false,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificación de evento social enviada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear evento: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<int?> _pickTeamId({String? emptyMessage}) async {
    try {
      final teams = MyTeamOption.dedupeByTeamId(await TeamService().getMyTeams());
      if (!mounted) return null;
      if (teams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emptyMessage ?? 'No tenés equipos asignados',
            ),
          ),
        );
        return null;
      }
      if (widget.initialTeamId != null) {
        final found = MyTeamOption.findInList(teams, widget.initialTeamId!);
        if (found != null) return found.teamId;
      }
      if (teams.length == 1) return teams.first.teamId;
      final picked = await showModalBottomSheet<MyTeamOption>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: teams
                .map(
                  (t) => ListTile(
                    title: Text(t.name),
                    onTap: () => Navigator.pop(ctx, t),
                  ),
                )
                .toList(),
          ),
        ),
      );
      return picked?.teamId;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  Future<void> _openAdminPanel() async {
    final teamId = await _pickTeamId();
    if (teamId == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamAdminPanelScreen(initialTeamId: teamId),
      ),
    );
  }

  Future<void> _openTeamQuotas() async {
    final teamId = await _pickTeamId();
    if (teamId == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotaOverviewScreen(teamId: teamId),
      ),
    );
  }

  Future<void> _openAttendance() async {
    final teamId = await _pickTeamId();
    if (teamId == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceScreen(teamId: teamId),
      ),
    );
  }

  Future<void> _openTeamInvite() async {
    try {
      final teams = await TeamService().getMyTeams();
      final adminTeams =
          teams.where((t) => t.isTeamAdmin).toList();
      if (!mounted) return;
      if (adminTeams.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo el encargado del equipo puede generar invitaciones. Creá un equipo en el onboarding.',
            ),
          ),
        );
        return;
      }
      MyTeamOption selected = adminTeams.first;
      if (adminTeams.length > 1) {
        final picked = await showModalBottomSheet<MyTeamOption>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: adminTeams
                  .map(
                    (t) => ListTile(
                      title: Text(t.name),
                      onTap: () => Navigator.pop(ctx, t),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        if (picked == null) return;
        selected = picked;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamInviteScreen(team: selected),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openSocialEventForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const EventFormScreen(
          initialEventType: SportEventType.social,
          socialOnly: true,
        ),
      ),
    );
    if (result == true && mounted) {
      _eventsKey.currentState?.reloadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento social creado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createStaffEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EventFormScreen()),
    );
    if (result == true && mounted) {
      _eventsKey.currentState?.reloadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento creado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addToRoster() async {
    final season = context.read<SeasonProvider>().season;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RosterFormImprovedScreen(season: season),
      ),
    );
    if (result == true && mounted) {
      _rosterListKey.currentState?.reloadRoster();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jugador agregado a la lista de buena fe'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createConvocation() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ConvocationFormScreen(),
      ),
    );
    if (result == true && mounted) {
      _convocationsKey.currentState?.reload();
      _eventsKey.currentState?.reloadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convocatoria guardada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Diálogos para las diferentes acciones
class _TrainingReminderDialog extends StatefulWidget {
  @override
  _TrainingReminderDialogState createState() => _TrainingReminderDialogState();
}

class _TrainingReminderDialogState extends State<_TrainingReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recordatorio de Entrenamiento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Fecha y hora',
                hintText: 'Ej: Mañana 19:00',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ej: Campo de entrenamiento',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duración',
                hintText: 'Ej: 90 minutos',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'date': _dateController.text,
                'location': _locationController.text,
                'duration': _durationController.text,
                'eventId': 1,
                'teamId': 2,
              });
            }
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class _PaymentReminderDialog extends StatefulWidget {
  @override
  _PaymentReminderDialogState createState() => _PaymentReminderDialogState();
}

class _PaymentReminderDialogState extends State<_PaymentReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _conceptController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _dueDateController.dispose();
    _conceptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recordatorio de Pago'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                hintText: 'Ej: 5000',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dueDateController,
              decoration: const InputDecoration(
                labelText: 'Fecha límite',
                hintText: 'Ej: 2024-02-20',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conceptController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Ej: Cuota mensual febrero',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'amount': double.tryParse(_amountController.text) ?? 0,
                'dueDate': _dueDateController.text,
                'concept': _conceptController.text,
                'userIds': [
                  1
                ], // Por ahora hardcodeado, después se puede hacer selección múltiple
                'teamId': 2,
              });
            }
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class _SocialEventDialog extends StatefulWidget {
  @override
  _SocialEventDialogState createState() => _SocialEventDialogState();
}

class _SocialEventDialogState extends State<_SocialEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  bool _hasExpenses = false;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Evento Social'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del evento',
                hintText: 'Ej: Asado de fin de temporada',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                hintText: 'Ej: Sábado 25/02',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ej: Quincho del club',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Tiene gastos compartidos'),
              subtitle:
                  const Text('Los gastos se dividirán entre participantes'),
              value: _hasExpenses,
              onChanged: (value) =>
                  setState(() => _hasExpenses = value ?? false),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'title': _titleController.text,
                'date': _dateController.text,
                'location': _locationController.text,
                'hasExpenses': _hasExpenses,
                'eventId': 1,
                'teamId': 2,
              });
            }
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

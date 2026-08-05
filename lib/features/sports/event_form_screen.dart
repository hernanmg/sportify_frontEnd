import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/season_provider.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/core/services/team_service.dart';
import 'package:sportify_amateur/core/services/roster_service.dart';
import 'package:sportify_amateur/core/services/event_expenses_service.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/utils/user_capabilities.dart';
import 'package:sportify_amateur/models/sport_event.dart';
import 'package:sportify_amateur/models/my_team_option.dart';
import 'package:sportify_amateur/features/sports/social_event_expenses_screen.dart';

class EventFormScreen extends StatefulWidget {
  final SportEvent? event;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int? initialTeamId;
  final SportEventType? initialEventType;
  /// Si es true, solo permite crear/editar eventos sociales (jugadores).
  final bool socialOnly;

  const EventFormScreen({
    Key? key,
    this.event,
    this.initialDate,
    this.initialTime,
    this.initialTeamId,
    this.initialEventType,
    this.socialOnly = false,
  }) : super(key: key);

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SportEventsService _eventsService = SportEventsService();
  final TeamService _teamService = TeamService();
  final RosterService _rosterService = RosterService();
  final EventExpensesService _eventExpensesService = EventExpensesService();

  List<MyTeamOption> _myTeams = [];
  MyTeamOption? _selectedTeam;
  final Set<int> _selectedCategoryIds = {};
  final Set<int> _selectedInviteeUserIds = {};
  List<_InviteeOption> _inviteeOptions = [];
  bool _loadingInvitees = false;
  bool _inviteAllTeam = true;

  final List<_ExternalGuestLine> _externalGuestLines = [_ExternalGuestLine()];

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _opponentController = TextEditingController();
  final _notesController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _estimatedCostController = TextEditingController();

  // Form values
  SportEventType _selectedType = SportEventType.training;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  DateTime? _confirmationDeadline;
  bool _isHomeMatch = true;
  bool _isOfficialMatch = false;
  bool _hasExpenses = false;
  bool _requiresConfirmation = true;
  bool _requiresPaymentUpToDate = false;
  bool _isLoading = false;
  bool _repeatWeekly = false;
  int _weeksAhead = 8;
  String? _userRole;

  List<SportEventType> get _selectableEventTypes {
    if (widget.socialOnly) return [SportEventType.social];
    if (UserCapabilities.canManageSportsEvents(_userRole)) {
      return SportEventType.values;
    }
    return [SportEventType.social];
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialEventType != null) {
      _selectedType = widget.initialEventType!;
    } else if (widget.socialOnly) {
      _selectedType = SportEventType.social;
    }
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialTime != null) {
      _selectedTime = widget.initialTime!;
    }
    _loadRole();
    _loadTeams();
    if (widget.event != null) {
      _loadEventData();
    }
  }

  Future<void> _loadRole() async {
    final role = await AuthStorageService().getRole();
    if (!mounted) return;
    setState(() {
      _userRole = role;
      if (!UserCapabilities.canManageSportsEvents(role) || widget.socialOnly) {
        _selectedType = SportEventType.social;
      }
    });
  }

  Future<void> _loadTeams() async {
    try {
      var teams = await _teamService.getMyTeams();
      if (teams.isEmpty) {
        final all = await _teamService.getAllTeams();
        teams = all
            .map(
              (t) => MyTeamOption(
                teamId: t.id,
                name: t.name,
                categories: t.category != null ? [t.category!] : [],
                team: t,
              ),
            )
            .toList();
      }
      teams = MyTeamOption.dedupeByTeamId(teams);
      final MyTeamOption? selected = widget.event != null
          ? MyTeamOption.findInList(teams, widget.event!.teamId)
          : (widget.initialTeamId != null
              ? MyTeamOption.findInList(teams, widget.initialTeamId!)
              : null);
      final resolved = selected ?? (teams.isNotEmpty ? teams.first : null);
      setState(() {
        _myTeams = teams;
        _selectedTeam = resolved;
        if (resolved != null) {
          _selectedCategoryIds
            ..clear()
            ..addAll(resolved.categoryIds);
        }
      });
      if (_selectedType == SportEventType.social) {
        await _loadInvitees();
      }
    } catch (_) {
      // El formulario mostrará aviso si no hay equipos
    }
  }

  Future<void> _onTeamChanged(MyTeamOption? team) async {
    setState(() {
      _selectedTeam = team;
      _selectedCategoryIds.clear();
      if (team != null) {
        _selectedCategoryIds.addAll(team.categoryIds);
      }
    });
    if ((_selectedType == SportEventType.social ||
            _selectedType == SportEventType.training) &&
        team != null) {
      await _loadInvitees();
    }
  }

  Future<void> _loadInvitees() async {
    final team = _selectedTeam;
    if (team == null) return;
    setState(() => _loadingInvitees = true);
    try {
      final season = context.read<SeasonProvider>().season;
      final categoryFilter = _selectedCategoryIds.isEmpty
          ? team.categoryIds
          : _selectedCategoryIds.toList();
      final roster = await _rosterService.getRosterByTeam(
        team.teamId,
        season: season,
        categoryIds:
            categoryFilter.isEmpty ? null : categoryFilter,
      );
      final guests = await _teamService.getTeamSocialGuests(team.teamId);

      final options = <_InviteeOption>[];
      final seenUsers = <int>{};

      for (final row in roster) {
        final userId = row.player?.userId;
        if (userId == null || seenUsers.contains(userId)) continue;
        seenUsers.add(userId);
        final name = row.player?.name ?? 'Jugador #$userId';
        options.add(_InviteeOption(
          userId: userId,
          label: '$name · ${row.category}',
          isGuest: false,
        ));
      }

      for (final g in guests) {
        final userId = g['userId'] as int?;
        if (userId == null || seenUsers.contains(userId)) continue;
        seenUsers.add(userId);
        options.add(_InviteeOption(
          userId: userId,
          label: '${g['displayName']} (invitado)',
          isGuest: true,
        ));
      }

      setState(() {
        _inviteeOptions = options;
        _selectedInviteeUserIds
          ..clear()
          ..addAll(options.map((o) => o.userId));
        _inviteAllTeam = true;
      });
    } catch (_) {
      setState(() => _inviteeOptions = []);
    } finally {
      if (mounted) setState(() => _loadingInvitees = false);
    }
  }

  void _loadEventData() {
    final event = widget.event!;
    _titleController.text = event.title;
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location ?? '';
    _durationController.text = event.durationMinutes?.toString() ?? '';
    _opponentController.text = event.opponentName ?? '';
    _notesController.text = event.notes ?? '';
    _maxParticipantsController.text = event.maxParticipants?.toString() ?? '';
    _estimatedCostController.text = event.estimatedCost?.toString() ?? '';

    _selectedType = event.type;
    _selectedDate = event.eventDate;
    _selectedTime = TimeOfDay.fromDateTime(event.eventDate);
    _confirmationDeadline = event.confirmationDeadline;
    _isHomeMatch = event.isHomeMatch;
    _isOfficialMatch = event.isOfficialMatch;
    _hasExpenses = event.hasExpenses;
    _requiresConfirmation = event.requiresConfirmation;
    _requiresPaymentUpToDate = event.requiresPaymentUpToDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _opponentController.dispose();
    _notesController.dispose();
    _maxParticipantsController.dispose();
    _estimatedCostController.dispose();
    for (final g in _externalGuestLines) {
      g.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Crear Evento' : 'Editar Evento'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveEvent,
              child: const Text('Guardar'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildTypeSpecificSection(),
              const SizedBox(height: 24),
              _buildParticipationSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_myTeams.isEmpty)
              const Text(
                'No tenés equipos asignados. Pedí al administrador que te agregue a la lista de buena fe.',
              )
            else
              DropdownButtonFormField<MyTeamOption>(
                value: _selectedTeam != null &&
                        _myTeams.any((t) => t.teamId == _selectedTeam!.teamId)
                    ? _selectedTeam
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Equipo *',
                  border: OutlineInputBorder(),
                  helperText: 'Solo equipos donde estás en la lista de buena fe',
                ),
                items: _myTeams
                    .map(
                      (team) => DropdownMenuItem(
                        value: team,
                        child: Text(team.name),
                      ),
                    )
                    .toList(),
                onChanged: _onTeamChanged,
                validator: (value) =>
                    value == null ? 'Seleccioná un equipo' : null,
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SportEventType>(
              value: _selectableEventTypes.contains(_selectedType)
                  ? _selectedType
                  : _selectableEventTypes.first,
              decoration: const InputDecoration(
                labelText: 'Tipo de evento',
                border: OutlineInputBorder(),
              ),
              items: _selectableEventTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getEventTypeName(type)),
                );
              }).toList(),
              onChanged: _selectableEventTypes.length <= 1
                  ? null
                  : (value) {
                setState(() {
                  _selectedType = value!;
                  // Resetear campos específicos del tipo anterior
                  if (_selectedType != SportEventType.match) {
                    _opponentController.clear();
                    _isHomeMatch = true;
                    _isOfficialMatch = false;
                  }
                  if (_selectedType != SportEventType.social) {
                    _hasExpenses = false;
                    _estimatedCostController.clear();
                    for (final g in _externalGuestLines) {
                      g.dispose();
                    }
                    _externalGuestLines
                      ..clear()
                      ..add(_ExternalGuestLine());
                  } else {
                    _loadInvitees();
                  }
                });
              },
              validator: (value) => value == null ? 'Selecciona un tipo' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título del evento',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El título es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fecha y Hora',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duración (minutos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Ingresa una duración válida';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificSection() {
    if (_selectedType == SportEventType.match) {
      return _buildMatchSection();
    }
    if (_selectedType == SportEventType.social) {
      return _buildSocialSection();
    }
    if (_selectedType == SportEventType.training) {
      return _buildTrainingSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildTrainingSection() {
    final team = _selectedTeam;
    if (team == null) return const SizedBox.shrink();
    final catIds = team.categoryIds;
    if (catIds.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categorías del entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elegí una o más categorías convocadas a este entreno.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(catIds.length, (i) {
                final id = catIds[i];
                final name =
                    i < team.categories.length ? team.categories[i] : 'Cat $id';
                final selected = _selectedCategoryIds.contains(id);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedCategoryIds.add(id);
                      } else {
                        _selectedCategoryIds.remove(id);
                      }
                    });
                  },
                );
              }),
            ),
            if (widget.event == null) ...[
              const Divider(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repetir semanalmente'),
                subtitle: Text(
                  'Crea $_weeksAhead entrenamientos en el mismo día y horario',
                ),
                value: _repeatWeekly,
                onChanged: (v) => setState(() => _repeatWeekly = v),
              ),
              if (_repeatWeekly)
                DropdownButtonFormField<int>(
                  initialValue: _weeksAhead,
                  decoration: const InputDecoration(
                    labelText: 'Semanas a generar',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text('4 semanas')),
                    DropdownMenuItem(value: 8, child: Text('8 semanas')),
                    DropdownMenuItem(value: 12, child: Text('12 semanas')),
                    DropdownMenuItem(value: 16, child: Text('16 semanas')),
                  ],
                  onChanged: (v) => setState(() => _weeksAhead = v ?? 8),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración del Partido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _opponentController,
              decoration: const InputDecoration(
                labelText: 'Rival/Oponente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Partido en casa'),
              subtitle: Text(_isHomeMatch ? 'Local' : 'Visitante'),
              value: _isHomeMatch,
              onChanged: (value) {
                setState(() {
                  _isHomeMatch = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Partido oficial'),
              subtitle: const Text('Solo jugadores con cuotas al día'),
              value: _isOfficialMatch,
              onChanged: (value) {
                setState(() {
                  _isOfficialMatch = value;
                  _requiresPaymentUpToDate = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    final team = _selectedTeam;
    return Column(
      children: [
        if (team != null && team.categoryIds.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categorías a convocar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(team.categoryIds.length, (i) {
                      final id = team.categoryIds[i];
                      final name = i < team.categories.length
                          ? team.categories[i]
                          : 'Cat $id';
                      final selected = _selectedCategoryIds.contains(id);
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (v) async {
                          setState(() {
                            if (v) {
                              _selectedCategoryIds.add(id);
                            } else {
                              _selectedCategoryIds.remove(id);
                            }
                          });
                          await _loadInvitees();
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'A quién invitar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _inviteeOptions.isEmpty
                          ? null
                          : () {
                              setState(() {
                                if (_inviteAllTeam) {
                                  _selectedInviteeUserIds.clear();
                                  _inviteAllTeam = false;
                                } else {
                                  _selectedInviteeUserIds.addAll(
                                    _inviteeOptions.map((o) => o.userId),
                                  );
                                  _inviteAllTeam = true;
                                }
                              });
                            },
                      child: Text(_inviteAllTeam ? 'Ninguno' : 'Todos'),
                    ),
                  ],
                ),
                if (_loadingInvitees)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_inviteeOptions.isEmpty)
                  const Text(
                    'No hay jugadores en las categorías elegidas. Agregalos en lista de buena fe.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ..._inviteeOptions.map((opt) {
                    return CheckboxListTile(
                      dense: true,
                      value: _selectedInviteeUserIds.contains(opt.userId),
                      title: Text(opt.label),
                      subtitle: opt.isGuest
                          ? const Text('Fuera del equipo')
                          : null,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedInviteeUserIds.add(opt.userId);
                          } else {
                            _selectedInviteeUserIds.remove(opt.userId);
                          }
                          _inviteAllTeam = _selectedInviteeUserIds.length ==
                              _inviteeOptions.length;
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildExternalGuestsCard(),
        const SizedBox(height: 16),
        Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración del Evento Social',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Tiene gastos compartidos'),
              subtitle: const Text(
                'Después de crear el evento podés cargar gastos (cada uno suma lo que pagó)',
              ),
              value: _hasExpenses,
              onChanged: (value) {
                setState(() {
                  _hasExpenses = value;
                  if (!value) {
                    _estimatedCostController.clear();
                  }
                });
              },
            ),
            if (_hasExpenses) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedCostController,
                decoration: const InputDecoration(
                  labelText: 'Costo estimado (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    ),
      ],
    );
  }

  Widget _buildExternalGuestsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invitados externos (sin cuenta en la app)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Para familiares u otras personas que no están en el equipo. '
              'Elegí de tus contactos del teléfono o cargá a mano.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickPhoneContacts,
              icon: const Icon(Icons.contacts),
              label: const Text('Elegir de mis contactos'),
            ),
            const SizedBox(height: 12),
            ...List.generate(_externalGuestLines.length, (i) {
              final line = _externalGuestLines[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: line.name,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: line.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        if (_externalGuestLines.length > 1)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                line.dispose();
                                _externalGuestLines.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: line.email,
                      decoration: const InputDecoration(
                        labelText: 'Email (opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _externalGuestLines.add(_ExternalGuestLine());
                  });
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Agregar otro invitado externo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Participación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxParticipantsController,
              decoration: const InputDecoration(
                labelText: 'Máximo de participantes (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Requiere confirmación'),
              subtitle: const Text('Los jugadores deben confirmar asistencia'),
              value: _requiresConfirmation,
              onChanged: (value) {
                setState(() {
                  _requiresConfirmation = value;
                  if (!value) {
                    _confirmationDeadline = null;
                  }
                });
              },
            ),
            if (_requiresConfirmation) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectConfirmationDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha límite de confirmación (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_available),
                  ),
                  child: Text(
                    _confirmationDeadline != null
                        ? '${_confirmationDeadline!.day.toString().padLeft(2, '0')}/${_confirmationDeadline!.month.toString().padLeft(2, '0')}/${_confirmationDeadline!.year} ${_confirmationDeadline!.hour.toString().padLeft(2, '0')}:${_confirmationDeadline!.minute.toString().padLeft(2, '0')}'
                        : 'Seleccionar fecha límite',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notas Adicionales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas o instrucciones especiales',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _selectConfirmationDeadline() async {
    final eventStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = eventStart.isAfter(now)
        ? eventStart
        : now.add(const Duration(days: 1));
    var initial = _confirmationDeadline ??
        eventStart.subtract(const Duration(hours: 2));
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _confirmationDeadline != null
            ? TimeOfDay.fromDateTime(_confirmationDeadline!)
            : const TimeOfDay(hour: 12, minute: 0),
      );
      if (time != null) {
        setState(() {
          _confirmationDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná un equipo para el evento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedType == SportEventType.training &&
        _selectedTeam!.categoryIds.isNotEmpty &&
        _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccioná al menos una categoría para el entrenamiento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'type': _selectedType.value,
        'eventDate': eventDateTime.toIso8601String(),
        'location':
            _locationController.text.isEmpty ? null : _locationController.text,
        'teamId': _selectedTeam!.teamId,
        'durationMinutes': _durationController.text.isEmpty
            ? null
            : int.tryParse(_durationController.text),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'maxParticipants': _maxParticipantsController.text.isEmpty
            ? null
            : int.tryParse(_maxParticipantsController.text),
        'requiresConfirmation': _requiresConfirmation,
        'confirmationDeadline': _confirmationDeadline?.toIso8601String(),

        // Para partidos
        if (_selectedType == SportEventType.match) ...{
          'opponentName': _opponentController.text.isEmpty
              ? null
              : _opponentController.text,
          'isHomeMatch': _isHomeMatch,
          'isOfficialMatch': _isOfficialMatch,
          'requiresPaymentUpToDate': _requiresPaymentUpToDate,
        },

        if (_selectedType == SportEventType.training &&
            _selectedCategoryIds.isNotEmpty)
          'categoryIds': _selectedCategoryIds.toList(),

        // Para eventos sociales
        if (_selectedType == SportEventType.social) ...{
          'hasExpenses': _hasExpenses,
          'estimatedCost': _estimatedCostController.text.isEmpty
              ? null
              : double.tryParse(_estimatedCostController.text),
          'autoInviteParticipants': false,
          if (_selectedInviteeUserIds.isNotEmpty)
            'participantIds': _selectedInviteeUserIds.toList(),
          if (_selectedCategoryIds.isNotEmpty)
            'categoryIds': _selectedCategoryIds.toList(),
        },
      };

      if (_selectedType == SportEventType.social) {
        final hasGuestUsers = _selectedInviteeUserIds.isNotEmpty;
        final extNames = _externalGuestLines
            .map((g) => g.name.text.trim())
            .where((n) => n.isNotEmpty);
        final hasExternal = extNames.isNotEmpty;
        if (!hasGuestUsers && !hasExternal) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Seleccioná al menos un invitado del plantel o cargá un invitado externo con nombre.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (widget.event == null) {
        if (_selectedType == SportEventType.training && _repeatWeekly) {
          final jsWeekday =
              eventDateTime.weekday == 7 ? 0 : eventDateTime.weekday;
          final result = await _eventsService.createTrainingSchedule({
            'teamId': _selectedTeam!.teamId,
            'title': _titleController.text,
            'description': _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            'weekday': jsWeekday,
            'hour': _selectedTime.hour,
            'minute': _selectedTime.minute,
            'durationMinutes': _durationController.text.isEmpty
                ? null
                : int.tryParse(_durationController.text),
            'location': _locationController.text.isEmpty
                ? null
                : _locationController.text,
            'categoryIds': _selectedCategoryIds.isEmpty
                ? null
                : _selectedCategoryIds.toList(),
            'weeksAhead': _weeksAhead,
            'notes': _notesController.text.isEmpty ? null : _notesController.text,
          });
          if (!mounted) return;
          final created = result['eventsCreated'] as int? ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                created > 0
                    ? 'Serie creada: $created entrenamiento(s) generados'
                    : 'Serie guardada (los entrenamientos ya existían)',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final created = await _eventsService.createEvent(eventData);
          if (!mounted) return;

          if (_selectedType == SportEventType.social) {
            for (final g in _externalGuestLines) {
              final name = g.name.text.trim();
              if (name.isEmpty) continue;
              try {
                await _eventExpensesService.addSocialGuest(
                  eventId: created.id,
                  displayName: name,
                  phone:
                      g.phone.text.trim().isEmpty ? null : g.phone.text.trim(),
                  email:
                      g.email.text.trim().isEmpty ? null : g.email.text.trim(),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('No se pudo registrar un invitado externo: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }

            if (!mounted) return;
            Navigator.pop(context, true);
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => SocialEventExpensesScreen(
                  eventId: created.id,
                  eventTitle: created.title,
                ),
              ),
            );
            return;
          }
        }
      } else {
        await _eventsService.updateEvent(widget.event!.id, eventData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.event == null
                ? 'Evento creado exitosamente'
                : 'Evento actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar evento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPhoneContacts() async {
    try {
      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        status = await Permission.contacts.request();
      }
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Necesitamos permiso de contactos para elegir invitados',
            ),
          ),
        );
        return;
      }

      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo acceder a los contactos')),
        );
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      final withPhone = contacts
          .where((c) => c.phones.isNotEmpty && c.displayName.trim().isNotEmpty)
          .toList()
        ..sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              ),
        );

      if (!mounted) return;
      if (withPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay contactos con teléfono')),
        );
        return;
      }

      final selected = <Contact>{};
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                builder: (_, scrollCtrl) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Contactos (${selected.length} elegidos)',
                                style: Theme.of(ctx).textTheme.titleMedium,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () => Navigator.pop(ctx, true),
                              child: const Text('Agregar'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: withPhone.length,
                          itemBuilder: (_, i) {
                            final c = withPhone[i];
                            final phone = c.phones.first.number;
                            final checked = selected.contains(c);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (v) {
                                setLocal(() {
                                  if (v == true) {
                                    selected.add(c);
                                  } else {
                                    selected.remove(c);
                                  }
                                });
                              },
                              title: Text(c.displayName),
                              subtitle: Text(phone),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        // Quitar línea vacía inicial si es la única.
        if (_externalGuestLines.length == 1 &&
            _externalGuestLines.first.name.text.trim().isEmpty &&
            _externalGuestLines.first.phone.text.trim().isEmpty) {
          _externalGuestLines.first.dispose();
          _externalGuestLines.clear();
        }
        for (final c in selected) {
          final line = _ExternalGuestLine();
          line.name.text = c.displayName;
          line.phone.text = c.phones.first.number;
          if (c.emails.isNotEmpty) {
            line.email.text = c.emails.first.address;
          }
          _externalGuestLines.add(line);
        }
        if (_externalGuestLines.isEmpty) {
          _externalGuestLines.add(_ExternalGuestLine());
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al leer contactos: $e')),
      );
    }
  }

  String _getEventTypeName(SportEventType type) {
    switch (type) {
      case SportEventType.training:
        return 'Entrenamiento';
      case SportEventType.match:
        return 'Partido';
      case SportEventType.social:
        return 'Evento Social';
      case SportEventType.meeting:
        return 'Reunión';
    }
  }
}

class _ExternalGuestLine {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();

  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
  }
}

class _InviteeOption {
  final int userId;
  final String label;
  final bool isGuest;

  _InviteeOption({
    required this.userId,
    required this.label,
    this.isGuest = false,
  });
}

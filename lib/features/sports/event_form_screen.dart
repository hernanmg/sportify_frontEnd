import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/sport_events_service.dart';
import 'package:sportify_amateur/models/sport_event.dart';

class EventFormScreen extends StatefulWidget {
  final SportEvent? event;

  const EventFormScreen({Key? key, this.event}) : super(key: key);

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SportEventsService _eventsService = SportEventsService();

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

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _loadEventData();
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
            DropdownButtonFormField<SportEventType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de evento',
                border: OutlineInputBorder(),
              ),
              items: SportEventType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getEventTypeName(type)),
                );
              }).toList(),
              onChanged: (value) {
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
    } else if (_selectedType == SportEventType.social) {
      return _buildSocialSection();
    }
    return const SizedBox.shrink();
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
    return Card(
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
              subtitle: const Text('Los participantes dividirán los gastos'),
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
                  if (_hasExpenses && (value == null || value.isEmpty)) {
                    return 'Ingresa un costo estimado';
                  }
                  return null;
                },
              ),
            ],
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
    final date = await showDatePicker(
      context: context,
      initialDate: _confirmationDeadline ??
          _selectedDate.subtract(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: _selectedDate,
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
        'teamId': 2, // Equipo con jugadores en roster
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

        // Para eventos sociales
        if (_selectedType == SportEventType.social) ...{
          'hasExpenses': _hasExpenses,
          'estimatedCost': _estimatedCostController.text.isEmpty
              ? null
              : double.tryParse(_estimatedCostController.text),
        },
      };

      if (widget.event == null) {
        await _eventsService.createEvent(eventData);
      } else {
        await _eventsService.updateEvent(widget.event!.id, eventData);
      }

      if (mounted) {
        Navigator.pop(
            context, true); // Retornar true para indicar que se guardó
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

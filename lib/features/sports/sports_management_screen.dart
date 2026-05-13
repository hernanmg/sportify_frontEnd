import 'package:flutter/material.dart';
import 'package:sportify_amateur/features/sports/roster_management_screen.dart';
import 'package:sportify_amateur/features/sports/events_management_screen.dart';
import 'package:sportify_amateur/features/sports/convocations_screen.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';

class SportsManagementScreen extends StatefulWidget {
  const SportsManagementScreen({Key? key}) : super(key: key);

  @override
  _SportsManagementScreenState createState() => _SportsManagementScreenState();
}

class _SportsManagementScreenState extends State<SportsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Deportiva'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt, size: 20),
              text: 'Lista de Buena Fe',
            ),
            Tab(
              icon: Icon(Icons.event, size: 20),
              text: 'Eventos',
            ),
            Tab(
              icon: Icon(Icons.sports_soccer, size: 20),
              text: 'Convocatorias',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'send_training_reminder',
                child: ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('Recordatorio Entrenamiento'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'send_payment_reminder',
                child: ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Recordatorio Pago'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'medical_alerts',
                child: ListTile(
                  leading: Icon(Icons.medical_services),
                  title: Text('Alertas Médicas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'social_event',
                child: ListTile(
                  leading: Icon(Icons.celebration),
                  title: Text('Evento Social'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RosterManagementScreen(),
          EventsManagementScreen(),
          ConvocationsScreen(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: // Lista de Buena Fe
        return FloatingActionButton(
          onPressed: () => _addToRoster(),
          tooltip: 'Agregar Jugador',
          child: const Icon(Icons.person_add),
        );
      case 1: // Eventos
        return FloatingActionButton(
          onPressed: () => _createEvent(),
          tooltip: 'Crear Evento',
          child: const Icon(Icons.add_circle),
        );
      case 2: // Convocatorias
        return FloatingActionButton(
          onPressed: () => _createConvocation(),
          tooltip: 'Nueva Convocatoria',
          child: const Icon(Icons.sports_soccer),
        );
      default:
        return null;
    }
  }

  void _handleMenuAction(String action) async {
    try {
      switch (action) {
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

  void _addToRoster() {
    // Esta funcionalidad ya está implementada en RosterManagementScreen
    // Se podría navegar directamente al formulario o delegar a la tab actual
  }

  void _createEvent() {
    // Navegar al formulario de creación de eventos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de eventos en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _createConvocation() {
    // Navegar al formulario de creación de convocatorias
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de convocatorias en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
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

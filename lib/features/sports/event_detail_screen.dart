import 'package:flutter/material.dart';
import 'package:sportify_amateur/models/sport_event.dart';
import 'package:sportify_amateur/features/sports/event_form_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final SportEvent event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late SportEvent _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEventHeader(),
            _buildEventDetails(),
            _buildParticipantsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEventColor(_event.type),
            _getEventColor(_event.type).withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEventIcon(_event.type),
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _event.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(_event.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                _event.formattedDate,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _event.timeUntilEvent,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (_event.location != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _event.location!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_event.description != null) ...[
            _buildDetailCard(
              'Descripción',
              Icons.description,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildDetailCard(
            'Información General',
            Icons.info,
            Column(
              children: [
                _buildDetailRow(
                    'Duración',
                    _event.durationMinutes != null
                        ? '${_event.durationMinutes} minutos'
                        : 'No especificada'),
                _buildDetailRow('Participantes', '${_event.participantCount}'),
                if (_event.maxParticipants != null)
                  _buildDetailRow(
                      'Máximo participantes', '${_event.maxParticipants}'),
                _buildDetailRow('Requiere confirmación',
                    _event.requiresConfirmation ? 'Sí' : 'No'),
                if (_event.confirmationDeadline != null)
                  _buildDetailRow('Fecha límite confirmación',
                      '${_event.confirmationDeadline!.day.toString().padLeft(2, '0')}/${_event.confirmationDeadline!.month.toString().padLeft(2, '0')}/${_event.confirmationDeadline!.year} ${_event.confirmationDeadline!.hour.toString().padLeft(2, '0')}:${_event.confirmationDeadline!.minute.toString().padLeft(2, '0')}'),
              ],
            ),
          ),
          if (_event.type == SportEventType.match) ...[
            const SizedBox(height: 16),
            _buildMatchDetails(),
          ],
          if (_event.type == SportEventType.social && _event.hasExpenses) ...[
            const SizedBox(height: 16),
            _buildSocialDetails(),
          ],
          if (_event.notes != null) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Notas',
              Icons.note,
              Text(
                _event.notes!,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchDetails() {
    return _buildDetailCard(
      'Detalles del Partido',
      Icons.sports_soccer,
      Column(
        children: [
          if (_event.opponentName != null)
            _buildDetailRow('Rival', _event.opponentName!),
          _buildDetailRow('Tipo', _event.isHomeMatch ? 'Local' : 'Visitante'),
          _buildDetailRow(
              'Modalidad', _event.isOfficialMatch ? 'Oficial' : 'Amistoso'),
          if (_event.isOfficialMatch)
            _buildDetailRow('Requisitos', 'Solo jugadores con cuotas al día'),
        ],
      ),
    );
  }

  Widget _buildSocialDetails() {
    return _buildDetailCard(
      'Detalles del Evento Social',
      Icons.celebration,
      Column(
        children: [
          _buildDetailRow(
              'Gastos compartidos', _event.hasExpenses ? 'Sí' : 'No'),
          if (_event.estimatedCost != null)
            _buildDetailRow('Costo estimado',
                '\$${_event.estimatedCost!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildDetailCard(
        'Participantes (${_event.participantCount})',
        Icons.people,
        Column(
          children: [
            if (_event.participants.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildParticipantStat(
                      'Confirmados', _event.confirmedCount, Colors.green),
                  _buildParticipantStat(
                      'Pendientes', _event.pendingCount, Colors.orange),
                  _buildParticipantStat(
                      'Rechazados', _event.declinedCount, Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ..._event.participants
                  .map((participant) => _buildParticipantTile(participant)),
            ] else ...[
              const Text(
                'No hay participantes registrados',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addParticipants,
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar Participantes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _getEventColor(_event.type)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(EventParticipant participant) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            _getParticipantStatusColor(participant.status).withOpacity(0.1),
        child: Icon(
          _getParticipantStatusIcon(participant.status),
          color: _getParticipantStatusColor(participant.status),
        ),
      ),
      title: Text(participant.userName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(participant.roleDisplayName),
          if (participant.playingPosition != null)
            Text('Posición: ${participant.playingPosition}'),
          if (participant.notes != null) Text('Nota: ${participant.notes}'),
        ],
      ),
      trailing: Chip(
        label: Text(
          participant.statusDisplayName,
          style: TextStyle(
            color: _getParticipantStatusColor(participant.status),
            fontSize: 12,
          ),
        ),
        backgroundColor:
            _getParticipantStatusColor(participant.status).withOpacity(0.1),
      ),
    );
  }

  Widget _buildStatusChip(SportEventStatus status) {
    Color color;
    String label;

    switch (status) {
      case SportEventStatus.draft:
        color = Colors.grey;
        label = 'Borrador';
        break;
      case SportEventStatus.scheduled:
        color = Colors.blue;
        label = 'Programado';
        break;
      case SportEventStatus.confirmed:
        color = Colors.green;
        label = 'Confirmado';
        break;
      case SportEventStatus.inProgress:
        color = Colors.amber;
        label = 'En progreso';
        break;
      case SportEventStatus.completed:
        color = Colors.teal;
        label = 'Completado';
        break;
      case SportEventStatus.cancelled:
        color = Colors.red;
        label = 'Cancelado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getEventColor(SportEventType type) {
    switch (type) {
      case SportEventType.training:
        return Colors.orange;
      case SportEventType.match:
        return Colors.green;
      case SportEventType.social:
        return Colors.pink;
      case SportEventType.meeting:
        return Colors.blue;
    }
  }

  IconData _getEventIcon(SportEventType type) {
    switch (type) {
      case SportEventType.training:
        return Icons.fitness_center;
      case SportEventType.match:
        return Icons.sports_soccer;
      case SportEventType.social:
        return Icons.celebration;
      case SportEventType.meeting:
        return Icons.meeting_room;
    }
  }

  Color _getParticipantStatusColor(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.confirmed:
        return Colors.green;
      case ParticipantStatus.pending:
        return Colors.orange;
      case ParticipantStatus.declined:
        return Colors.red;
      case ParticipantStatus.noResponse:
        return Colors.grey;
    }
  }

  IconData _getParticipantStatusIcon(ParticipantStatus status) {
    switch (status) {
      case ParticipantStatus.confirmed:
        return Icons.check_circle;
      case ParticipantStatus.pending:
        return Icons.schedule;
      case ParticipantStatus.declined:
        return Icons.cancel;
      case ParticipantStatus.noResponse:
        return Icons.help;
    }
  }

  void _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(event: _event),
      ),
    );

    if (result == true) {
      // Aquí deberías recargar el evento desde el servidor
      // Por ahora, simplemente mostramos un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento actualizado'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addParticipants() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Participantes'),
        content:
            const Text('Funcionalidad de agregar participantes en desarrollo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

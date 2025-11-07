import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';

class ConvocationsScreen extends StatefulWidget {
  const ConvocationsScreen({Key? key}) : super(key: key);

  @override
  _ConvocationsScreenState createState() => _ConvocationsScreenState();
}

class _ConvocationsScreenState extends State<ConvocationsScreen> {
  final NotificationService _notificationService = NotificationService();

  final List<Map<String, dynamic>> _convocations = [
    {
      'id': 1,
      'title': 'Partido vs Rival FC',
      'date': '2024-02-18 16:00',
      'opponent': 'Rival FC',
      'location': 'Estadio Central',
      'type': 'official',
      'convocados': 18,
      'confirmados': 15,
      'pendientes': 3,
      'status': 'sent',
      'sentDate': '2024-02-15 10:00',
    },
    {
      'id': 2,
      'title': 'Partido Amistoso vs Local United',
      'date': '2024-02-22 15:00',
      'opponent': 'Local United',
      'location': 'Cancha del club',
      'type': 'friendly',
      'convocados': 16,
      'confirmados': 12,
      'pendientes': 4,
      'status': 'draft',
      'sentDate': null,
    },
  ];

  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _buildConvocationsList(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Filtrar convocatorias',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Todas')),
                DropdownMenuItem(value: 'sent', child: Text('Enviadas')),
                DropdownMenuItem(value: 'draft', child: Text('Borradores')),
                DropdownMenuItem(
                    value: 'official', child: Text('Partidos oficiales')),
                DropdownMenuItem(value: 'friendly', child: Text('Amistosos')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value ?? 'all';
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _createConvocation,
            icon: const Icon(Icons.add),
            label: const Text('Nueva'),
          ),
        ],
      ),
    );
  }

  Widget _buildConvocationsList() {
    final filteredConvocations = _getFilteredConvocations();

    if (filteredConvocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay convocatorias',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'No tienes convocatorias creadas'
                  : 'No hay convocatorias de este tipo',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredConvocations.length,
      itemBuilder: (context, index) {
        final convocation = filteredConvocations[index];
        return _buildConvocationCard(convocation);
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredConvocations() {
    if (_selectedFilter == 'all') return _convocations;

    return _convocations.where((conv) {
      switch (_selectedFilter) {
        case 'sent':
          return conv['status'] == 'sent';
        case 'draft':
          return conv['status'] == 'draft';
        case 'official':
          return conv['type'] == 'official';
        case 'friendly':
          return conv['type'] == 'friendly';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildConvocationCard(Map<String, dynamic> convocation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildConvocationIcon(convocation['type']),
        title: Text(
          convocation['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(convocation['date']),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(child: Text(convocation['location'])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChip(convocation['status']),
                const Spacer(),
                _buildTypeChip(convocation['type']),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleConvocationAction(value, convocation),
          itemBuilder: (context) => [
            if (convocation['status'] == 'draft')
              const PopupMenuItem(
                value: 'send',
                child: ListTile(
                  leading: Icon(Icons.send, color: Colors.green),
                  title: Text('Enviar convocatoria'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'responses',
              child: ListTile(
                leading: Icon(Icons.poll),
                title: Text('Ver respuestas'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'resend',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Reenviar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(convocation),
                const SizedBox(height: 16),
                _buildConvocationDetails(convocation),
                const SizedBox(height: 16),
                _buildActionButtons(convocation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvocationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'official':
        iconData = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case 'friendly':
        iconData = Icons.handshake;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.sports;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'sent':
        color = Colors.green;
        label = 'Enviada';
        break;
      case 'draft':
        color = Colors.orange;
        label = 'Borrador';
        break;
      default:
        color = Colors.grey;
        label = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'official':
        color = Colors.red;
        label = 'Oficial';
        break;
      case 'friendly':
        color = Colors.blue;
        label = 'Amistoso';
        break;
      default:
        color = Colors.grey;
        label = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> convocation) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Convocados',
            convocation['convocados'].toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Confirmados',
            convocation['confirmados'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Pendientes',
            convocation['pendientes'].toString(),
            Icons.schedule,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvocationDetails(Map<String, dynamic> convocation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles del partido:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Rival', convocation['opponent']),
        _buildDetailRow('Fecha y hora', convocation['date']),
        _buildDetailRow('Ubicación', convocation['location']),
        if (convocation['sentDate'] != null)
          _buildDetailRow('Enviada el', convocation['sentDate']),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> convocation) {
    return Row(
      children: [
        if (convocation['status'] == 'draft')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _sendConvocation(convocation),
              icon: const Icon(Icons.send),
              label: const Text('Enviar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
        if (convocation['status'] == 'sent') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _viewResponses(convocation),
              icon: const Icon(Icons.poll),
              label: const Text('Respuestas'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _resendConvocation(convocation),
              icon: const Icon(Icons.refresh),
              label: const Text('Reenviar'),
            ),
          ),
        ],
      ],
    );
  }

  void _createConvocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Convocatoria'),
        content: const Text(
            'Funcionalidad de creación de convocatorias en desarrollo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _handleConvocationAction(
      String action, Map<String, dynamic> convocation) {
    switch (action) {
      case 'send':
        _sendConvocation(convocation);
        break;
      case 'edit':
        _editConvocation(convocation);
        break;
      case 'responses':
        _viewResponses(convocation);
        break;
      case 'resend':
        _resendConvocation(convocation);
        break;
      case 'delete':
        _deleteConvocation(convocation);
        break;
    }
  }

  Future<void> _sendConvocation(Map<String, dynamic> convocation) async {
    try {
      await _notificationService.sendMatchInvitation(
        eventId: convocation['id'],
        teamId: 2, // Equipo con jugadores en roster
        matchDetails: {
          'date': convocation['date'],
          'opponent': convocation['opponent'],
          'location': convocation['location'],
        },
      );

      setState(() {
        convocation['status'] = 'sent';
        convocation['sentDate'] = DateTime.now().toString().substring(0, 16);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Convocatoria enviada: ${convocation['title']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar convocatoria: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editConvocation(Map<String, dynamic> convocation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar convocatoria: ${convocation['title']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewResponses(Map<String, dynamic> convocation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Respuestas - ${convocation['title']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResponseSummary(convocation),
              const SizedBox(height: 16),
              const Text('Lista detallada de respuestas en desarrollo...'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseSummary(Map<String, dynamic> convocation) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                convocation['confirmados'].toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text('Confirmados'),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                convocation['pendientes'].toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Text('Pendientes'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resendConvocation(Map<String, dynamic> convocation) async {
    await _sendConvocation(convocation);
  }

  void _deleteConvocation(Map<String, dynamic> convocation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Convocatoria'),
        content: Text(
            '¿Estás seguro de que quieres eliminar "${convocation['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _convocations.removeWhere((c) => c['id'] == convocation['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Convocatoria eliminada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

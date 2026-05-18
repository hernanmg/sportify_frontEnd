import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/convocations_service.dart';
import 'package:sportify_amateur/core/services/notification_service.dart';
import 'package:sportify_amateur/models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  late TabController _tabController;

  final List<String> _filterOptions = [
    'all',
    'unread',
    'match_invitation',
    'training_reminder',
    'payment_reminder',
    'medical_expiry',
    'social_event',
  ];

  final Map<String, String> _filterLabels = {
    'all': 'Todas',
    'unread': 'No leídas',
    'match_invitation': 'Convocatorias',
    'training_reminder': 'Entrenamientos',
    'payment_reminder': 'Pagos',
    'medical_expiry': 'Apto Médico',
    'social_event': 'Eventos Sociales',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      final notifications = await _notificationService.getMyNotifications();
      setState(() {
        _notifications = notifications;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case 'all':
        _filteredNotifications = _notifications;
        break;
      case 'unread':
        _filteredNotifications =
            NotificationService.filterUnread(_notifications);
        break;
      case 'match_invitation':
        _filteredNotifications = NotificationService.filterByType(
            _notifications, NotificationType.matchInvitation);
        break;
      case 'training_reminder':
        _filteredNotifications = NotificationService.filterByType(
            _notifications, NotificationType.trainingReminder);
        break;
      case 'payment_reminder':
        _filteredNotifications = NotificationService.filterByType(
            _notifications, NotificationType.paymentReminder);
        break;
      case 'medical_expiry':
        _filteredNotifications = NotificationService.filterByType(
            _notifications, NotificationType.medicalExpiry);
        break;
      case 'social_event':
        _filteredNotifications = NotificationService.filterByType(
            _notifications, NotificationType.socialEvent);
        break;
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _notificationService.markAsRead(notification.id);
        await _loadNotifications();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al marcar como leída: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recientes', icon: Icon(Icons.notifications)),
            Tab(text: 'Filtros', icon: Icon(Icons.filter_list)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Marcar todas como leídas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(),
          _buildFiltersView(),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'No tienes notificaciones aún'
                  : 'No hay notificaciones de este tipo',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: _buildNotificationIcon(notification),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildPriorityChip(notification.priority),
                const SizedBox(width: 8),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (notification.teamName != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.group, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Text(
                    notification.teamName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          _markAsRead(notification);
          _showNotificationDetail(notification);
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.matchInvitation:
        iconData = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case NotificationType.trainingReminder:
        iconData = Icons.fitness_center;
        iconColor = Colors.orange;
        break;
      case NotificationType.paymentReminder:
        iconData = Icons.payment;
        iconColor = Colors.red;
        break;
      case NotificationType.medicalExpiry:
        iconData = Icons.medical_services;
        iconColor = Colors.purple;
        break;
      case NotificationType.socialEvent:
        iconData = Icons.celebration;
        iconColor = Colors.pink;
        break;
      case NotificationType.rosterUpdate:
        iconData = Icons.list_alt;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildPriorityChip(NotificationPriority priority) {
    Color color;
    switch (priority) {
      case NotificationPriority.urgent:
        color = Colors.red;
        break;
      case NotificationPriority.high:
        color = Colors.orange;
        break;
      case NotificationPriority.medium:
        color = Colors.blue;
        break;
      case NotificationPriority.low:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFiltersView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Filtrar por tipo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._filterOptions.map((filter) {
          final count = _getFilterCount(filter);
          return Card(
            child: ListTile(
              leading: _getFilterIcon(filter),
              title: Text(_filterLabels[filter] ?? filter),
              trailing: count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              selected: _selectedFilter == filter,
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter();
                });
                _tabController.animateTo(0);
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _getFilterIcon(String filter) {
    switch (filter) {
      case 'all':
        return const Icon(Icons.notifications);
      case 'unread':
        return const Icon(Icons.mark_email_unread);
      case 'match_invitation':
        return const Icon(Icons.sports_soccer);
      case 'training_reminder':
        return const Icon(Icons.fitness_center);
      case 'payment_reminder':
        return const Icon(Icons.payment);
      case 'medical_expiry':
        return const Icon(Icons.medical_services);
      case 'social_event':
        return const Icon(Icons.celebration);
      default:
        return const Icon(Icons.notifications);
    }
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'all':
        return _notifications.length;
      case 'unread':
        return NotificationService.filterUnread(_notifications).length;
      case 'match_invitation':
        return NotificationService.filterByType(
                _notifications, NotificationType.matchInvitation)
            .length;
      case 'training_reminder':
        return NotificationService.filterByType(
                _notifications, NotificationType.trainingReminder)
            .length;
      case 'payment_reminder':
        return NotificationService.filterByType(
                _notifications, NotificationType.paymentReminder)
            .length;
      case 'medical_expiry':
        return NotificationService.filterByType(
                _notifications, NotificationType.medicalExpiry)
            .length;
      case 'social_event':
        return NotificationService.filterByType(
                _notifications, NotificationType.socialEvent)
            .length;
      default:
        return 0;
    }
  }

  void _showNotificationDetail(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NotificationDetailSheet(
        notification: notification,
        onResponse: () => _loadNotifications(),
      ),
    );
  }
}

class NotificationDetailSheet extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback? onResponse;

  const NotificationDetailSheet({
    Key? key,
    required this.notification,
    this.onResponse,
  }) : super(key: key);

  @override
  State<NotificationDetailSheet> createState() =>
      _NotificationDetailSheetState();
}

class _NotificationDetailSheetState extends State<NotificationDetailSheet> {
  final _convocationsService = ConvocationsService();
  bool _responding = false;

  NotificationModel get notification => widget.notification;

  Future<void> _respond(bool confirm) async {
    final eventId = notification.convocationEventId;
    if (eventId == null) return;
    setState(() => _responding = true);
    try {
      if (confirm) {
        await _convocationsService.confirmParticipation(eventId);
      } else {
        await _convocationsService.declineParticipation(eventId);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onResponse?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              confirm ? 'Asistencia confirmada' : 'Participación rechazada',
            ),
            backgroundColor: confirm ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showConvocationActions =
        notification.isConvocationResponse &&
        notification.convocationEventId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildNotificationIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      notification.typeDisplayName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notification.message,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (notification.data != null) ...[
            const Text(
              'Detalles adicionales:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDataDetails(),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Recibido ${notification.timeAgo}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Spacer(),
              _buildPriorityChip(),
            ],
          ),
          if (showConvocationActions) ...[
            const SizedBox(height: 16),
            const Text(
              '¿Podés asistir al partido?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _responding ? null : () => _respond(true),
                    icon: _responding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Confirmar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _responding ? null : () => _respond(false),
                    icon: const Icon(Icons.close),
                    label: const Text('No puedo'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.matchInvitation:
        iconData = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case NotificationType.trainingReminder:
        iconData = Icons.fitness_center;
        iconColor = Colors.orange;
        break;
      case NotificationType.paymentReminder:
        iconData = Icons.payment;
        iconColor = Colors.red;
        break;
      case NotificationType.medicalExpiry:
        iconData = Icons.medical_services;
        iconColor = Colors.purple;
        break;
      case NotificationType.socialEvent:
        iconData = Icons.celebration;
        iconColor = Colors.pink;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildDataDetails() {
    if (notification.data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: notification.data!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatKey(entry.key)}: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(entry.value.toString()),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatKey(String key) {
    switch (key) {
      case 'matchDate':
        return 'Fecha del partido';
      case 'opponent':
        return 'Rival';
      case 'location':
        return 'Ubicación';
      case 'trainingDate':
        return 'Fecha de entrenamiento';
      case 'duration':
        return 'Duración';
      case 'amount':
        return 'Monto';
      case 'dueDate':
        return 'Fecha límite';
      case 'concept':
        return 'Concepto';
      case 'expiryDate':
        return 'Fecha de vencimiento';
      case 'daysUntilExpiry':
        return 'Días restantes';
      default:
        return key;
    }
  }

  Widget _buildPriorityChip() {
    Color color;
    switch (notification.priority) {
      case NotificationPriority.urgent:
        color = Colors.red;
        break;
      case NotificationPriority.high:
        color = Colors.orange;
        break;
      case NotificationPriority.medium:
        color = Colors.blue;
        break;
      case NotificationPriority.low:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        notification.priorityDisplayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

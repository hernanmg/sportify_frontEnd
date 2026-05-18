enum NotificationType {
  matchInvitation('match_invitation'),
  trainingReminder('training_reminder'),
  paymentReminder('payment_reminder'),
  socialEvent('social_event'),
  medicalExpiry('medical_expiry'),
  general('general'),
  rosterUpdate('roster_update'),
  eventCancelled('event_cancelled'),
  eventPostponed('event_postponed'),
  eventRescheduled('event_rescheduled'),
  eventCompleted('event_completed'),
  eventStarted('event_started'),
  impedimentCleared('impediment_cleared'),
  playerEligible('player_eligible');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

enum NotificationPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }
}

class NotificationModel {
  final int id;
  final int userId;
  final int? teamId;
  final int? eventId;
  final int? sportEventId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? scheduledFor;
  final bool sent;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones opcionales
  final String? teamName;
  final String? eventTitle;

  NotificationModel({
    required this.id,
    required this.userId,
    this.teamId,
    this.eventId,
    this.sportEventId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    this.scheduledFor,
    required this.sent,
    required this.createdAt,
    required this.updatedAt,
    this.teamName,
    this.eventTitle,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse('${json['id']}') ?? DateTime.now().millisecondsSinceEpoch,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      teamId: json['teamId'] ?? json['team_id'],
      eventId: json['eventId'] ?? json['event_id'],
      sportEventId: json['sportEventId'] ?? json['sport_event_id'],
      type: NotificationType.fromString(json['type'] ?? 'general'),
      priority: NotificationPriority.fromString(json['priority'] ?? 'medium'),
      title: json['title'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : json['read_at'] != null
              ? DateTime.tryParse(json['read_at'].toString())
              : null,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'].toString())
          : json['scheduled_for'] != null
              ? DateTime.tryParse(json['scheduled_for'].toString())
              : null,
      sent: json['sent'] ?? true,
      createdAt: DateTime.tryParse(
              json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      teamName: json['team']?['name'],
      eventTitle: json['sportEvent']?['title'] ?? json['event']?['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'teamId': teamId,
      'eventId': eventId,
      'type': type.value,
      'priority': priority.value,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'sent': sent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helpers para UI
  String get typeDisplayName {
    switch (type) {
      case NotificationType.matchInvitation:
        return 'Convocatoria';
      case NotificationType.trainingReminder:
        return 'Entrenamiento';
      case NotificationType.paymentReminder:
        return 'Pago';
      case NotificationType.socialEvent:
        return 'Evento Social';
      case NotificationType.medicalExpiry:
        return 'Apto Médico';
      case NotificationType.rosterUpdate:
        return 'Lista de Buena Fe';
      case NotificationType.general:
        return 'General';
      case NotificationType.eventCancelled:
        return 'Evento Cancelado';
      case NotificationType.eventPostponed:
        return 'Evento Pospuesto';
      case NotificationType.eventRescheduled:
        return 'Evento Reprogramado';
      case NotificationType.eventCompleted:
        return 'Evento Finalizado';
      case NotificationType.eventStarted:
        return 'Evento Iniciado';
      case NotificationType.impedimentCleared:
        return 'Alta médica';
      case NotificationType.playerEligible:
        return 'Habilitado';
    }
  }

  int? get convocationEventId {
    if (sportEventId != null) return sportEventId;
    final fromData = data?['sportEventId'];
    if (fromData != null) return int.tryParse('$fromData');
    return null;
  }

  bool get isConvocationResponse =>
      type == NotificationType.matchInvitation ||
      data?['action'] == 'convocation_response';

  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Baja';
      case NotificationPriority.medium:
        return 'Media';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  bool get isUrgent {
    return priority == NotificationPriority.urgent;
  }

  // Crear copia con cambios
  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      teamId: teamId,
      eventId: eventId,
      type: type,
      priority: priority,
      title: title,
      message: message,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      scheduledFor: scheduledFor,
      sent: sent,
      createdAt: createdAt,
      updatedAt: updatedAt,
      teamName: teamName,
      eventTitle: eventTitle,
    );
  }
}

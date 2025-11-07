enum NotificationType {
  matchInvitation('match_invitation'),
  trainingReminder('training_reminder'),
  paymentReminder('payment_reminder'),
  socialEvent('social_event'),
  medicalExpiry('medical_expiry'),
  general('general'),
  rosterUpdate('roster_update');

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
      id: json['id'],
      userId: json['userId'] ?? json['user_id'],
      teamId: json['teamId'] ?? json['team_id'],
      eventId: json['eventId'] ?? json['event_id'],
      sportEventId: json['sportEventId'] ?? json['sport_event_id'],
      type: NotificationType.fromString(json['type'] ?? 'general'),
      priority: NotificationPriority.fromString(json['priority'] ?? 'medium'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : json['read_at'] != null
              ? DateTime.parse(json['read_at'])
              : null,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : json['scheduled_for'] != null
              ? DateTime.parse(json['scheduled_for'])
              : null,
      sent: json['sent'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
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
    }
  }

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

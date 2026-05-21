import 'dart:convert';

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

  static Map<String, dynamic>? _parseData(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

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
      data: _parseData(json['data']),
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

  /// Navegación a Gestión deportiva → pestaña Estado jugadores.
  bool get opensPlayerStatus {
    if (type == NotificationType.impedimentCleared) return true;
    final action = data?['action']?.toString();
    if (action == 'open_player_status') return true;
    final deepLink = data?['deepLink']?.toString();
    if (deepLink == '/sports/roster') return true;
    final t = title.toLowerCase();
    if (t.contains('impedimento') ||
        t.contains('lesión') ||
        t.contains('lesion') ||
        t.contains('suspensión') ||
        t.contains('suspension') ||
        t.contains('alta médica') ||
        t.contains('habilitado')) {
      return true;
    }
    final m = message.toLowerCase();
    if (m.contains('lesión') ||
        m.contains('lesion') ||
        m.contains('suspensión') ||
        m.contains('suspension') ||
        m.contains('impedimento')) {
      return true;
    }
    final details = data?['details'];
    if (details is List) {
      for (final item in details) {
        if (item is Map && item['label']?.toString() == 'Tipo') {
          final v = item['value']?.toString().toLowerCase() ?? '';
          if (v.contains('lesión') ||
              v.contains('lesion') ||
              v.contains('suspensión') ||
              v.contains('suspension') ||
              v.contains('impedimento')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  int? get navigationTeamId {
    final fromData = data?['teamId'];
    if (fromData != null) return int.tryParse('$fromData');
    return teamId;
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

  /// Claves solo para la app (navegación, FCM). No mostrar al usuario.
  static const Set<String> _internalDataKeys = {
    'action',
    'deepLink',
    'teamId',
    'tenantId',
    'sportEventId',
    'eventId',
    'userId',
    'reportedByUserId',
    'impedimentType',
    'playerName',
    'description',
    'details',
    'squadSummary',
  };

  /// Filas listas para mostrar (español), generadas por el backend en `data.details`.
  List<({String label, String value})> get userFacingDetails {
    final rawDetails = data?['details'];
    if (rawDetails is List) {
      final rows = <({String label, String value})>[];
      for (final item in rawDetails) {
        if (item is! Map) continue;
        final label = item['label']?.toString();
        final value = item['value']?.toString();
        if (label != null &&
            label.isNotEmpty &&
            value != null &&
            value.isNotEmpty) {
          rows.add((label: label, value: value));
        }
      }
      if (rows.isNotEmpty) return rows;
    }

    if (data == null) return [];
    final rows = <({String label, String value})>[];
    for (final entry in data!.entries) {
      if (_internalDataKeys.contains(entry.key)) continue;
      final text = formatDataValue(entry.key, entry.value);
      if (text.isEmpty) continue;
      rows.add((label: formatDataKey(entry.key), value: text));
    }
    return rows;
  }

  static String formatDataKey(String key) {
    switch (key) {
      case 'matchDate':
        return 'Fecha del partido';
      case 'opponent':
        return 'Rival';
      case 'location':
        return 'Ubicación';
      case 'courtNumber':
        return 'Cancha';
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
      case 'reportedByName':
        return 'Registrado por';
      case 'clearedByName':
        return 'Dado de alta por';
      case 'categoryLabel':
        return 'Categoría';
      case 'impedimentTypeLabel':
        return 'Tipo';
      case 'clinicalDescription':
        return 'Observaciones';
      case 'startDate':
        return 'Desde';
      case 'endDate':
        return 'Hasta';
      default:
        return key;
    }
  }

  static String formatDataValue(String key, dynamic value) {
    if (value == null) return '';
    if (key == 'impedimentType') {
      switch (value.toString()) {
        case 'injury':
          return 'Lesión';
        case 'suspension':
          return 'Suspensión';
        case 'other':
          return 'Otro impedimento';
        default:
          return value.toString();
      }
    }
    return value.toString();
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

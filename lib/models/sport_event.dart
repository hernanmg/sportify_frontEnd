enum SportEventType {
  training('training'),
  match('match'),
  social('social'),
  meeting('meeting');

  const SportEventType(this.value);
  final String value;

  static SportEventType fromString(String value) {
    return SportEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SportEventType.training,
    );
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _avatarUrlFromParticipantJson(dynamic user) {
  if (user is! Map) return null;
  final map = Map<String, dynamic>.from(user);
  final url = map['avatarUrl'] ?? map['avatar_url'];
  if (url == null || url.toString().trim().isEmpty) return null;
  return url.toString();
}

String? _userNameFromParticipantJson(dynamic user) {
  if (user is! Map) return null;
  final map = Map<String, dynamic>.from(user);
  final first = map['firstName'] ?? map['first_name'];
  final last = map['lastName'] ?? map['last_name'];
  final combined = [first, last]
      .where((p) => p != null && p.toString().trim().isNotEmpty)
      .map((p) => p.toString())
      .join(' ')
      .trim();
  if (combined.isNotEmpty) return combined;
  return map['username']?.toString();
}

enum SportEventStatus {
  draft('draft'),
  scheduled('scheduled'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  postponed('postponed');

  const SportEventStatus(this.value);
  final String value;

  static SportEventStatus fromString(String value) {
    return SportEventStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SportEventStatus.scheduled,
    );
  }
}

enum ParticipantStatus {
  pending('pending'),
  confirmed('confirmed'),
  declined('declined'),
  noResponse('no_response');

  const ParticipantStatus(this.value);
  final String value;

  static ParticipantStatus fromString(String value) {
    return ParticipantStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ParticipantStatus.pending,
    );
  }
}

enum ParticipantRole {
  player('player'),
  substitute('substitute'),
  coach('coach'),
  staff('staff');

  const ParticipantRole(this.value);
  final String value;

  static ParticipantRole fromString(String value) {
    return ParticipantRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ParticipantRole.player,
    );
  }
}

class EventParticipant {
  final int id;
  final int eventId;
  final int userId;
  final String userName;
  final String? avatarUrl;
  final String? userEmail;
  final ParticipantStatus status;
  final ParticipantRole role;
  final DateTime? responseDate;
  final String? notes;
  final double? expenseShare;
  final bool hasPaidExpenses;
  final String? playingPosition;
  final bool? attended;
  final String? attendanceNotes;
  final bool isConvoked;
  final String? eligibilityStatus;
  final String? eligibilityDetail;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.userEmail,
    required this.status,
    required this.role,
    this.responseDate,
    this.notes,
    this.expenseShare,
    required this.hasPaidExpenses,
    this.playingPosition,
    this.attended,
    this.attendanceNotes,
    this.isConvoked = true,
    this.eligibilityStatus,
    this.eligibilityDetail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'],
      eventId: json['eventId'] ?? json['event_id'],
      userId: json['userId'] ?? json['user_id'],
      userName: _userNameFromParticipantJson(json['user']) ??
          json['userName'] as String? ??
          'Usuario',
      avatarUrl: _avatarUrlFromParticipantJson(json['user']),
      userEmail: json['user']?['email'] ?? json['userEmail'],
      status: ParticipantStatus.fromString(json['status'] ?? 'pending'),
      role: ParticipantRole.fromString(json['role'] ?? 'player'),
      responseDate: json['responseDate'] != null
          ? DateTime.parse(json['responseDate'])
          : json['response_date'] != null
              ? DateTime.parse(json['response_date'])
              : null,
      notes: json['notes'],
      expenseShare: _parseDouble(json['expenseShare'] ?? json['expense_share']),
      hasPaidExpenses:
          json['hasPaidExpenses'] ?? json['has_paid_expenses'] ?? false,
      playingPosition: json['playingPosition'] ?? json['playing_position'],
      attended: json['attended'],
      attendanceNotes: json['attendanceNotes'] ?? json['attendance_notes'],
      isConvoked: json['isConvoked'] ?? json['is_convoked'] ?? true,
      eligibilityStatus:
          json['eligibilityStatus'] ?? json['eligibility_status'],
      eligibilityDetail:
          json['eligibilityDetail'] ?? json['eligibility_detail'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'status': status.value,
      'role': role.value,
      'responseDate': responseDate?.toIso8601String(),
      'notes': notes,
      'expenseShare': expenseShare,
      'hasPaidExpenses': hasPaidExpenses,
      'playingPosition': playingPosition,
      'attended': attended,
      'attendanceNotes': attendanceNotes,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case ParticipantStatus.pending:
        return 'Pendiente';
      case ParticipantStatus.confirmed:
        return 'Confirmado';
      case ParticipantStatus.declined:
        return 'Rechazado';
      case ParticipantStatus.noResponse:
        return 'Sin respuesta';
    }
  }

  String get roleDisplayName {
    switch (role) {
      case ParticipantRole.player:
        return 'Jugador';
      case ParticipantRole.substitute:
        return 'Suplente';
      case ParticipantRole.coach:
        return 'Entrenador';
      case ParticipantRole.staff:
        return 'Staff';
    }
  }
}

class SportEvent {
  final int id;
  final String title;
  final String? description;
  final SportEventType type;
  final SportEventStatus status;
  final DateTime eventDate;
  final int? durationMinutes;
  final String? location;
  final String? courtNumber;
  final int teamId;
  final String? teamName;
  final int createdBy;
  final String? creatorName;

  // Para partidos
  final String? opponentName;
  final bool isHomeMatch;
  final bool isOfficialMatch;

  // Para eventos sociales
  final bool hasExpenses;
  final double? estimatedCost;

  // Configuración de participación
  final int? maxParticipants;
  final bool requiresConfirmation;
  final DateTime? confirmationDeadline;
  final bool requiresPaymentUpToDate;

  final String? notes;
  final Map<String, dynamic>? metadata;
  final bool postMatchVotingClosed;
  final List<EventParticipant> participants;
  final String? myParticipationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  SportEvent({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.status,
    required this.eventDate,
    this.durationMinutes,
    this.location,
    this.courtNumber,
    required this.teamId,
    this.teamName,
    required this.createdBy,
    this.creatorName,
    this.opponentName,
    required this.isHomeMatch,
    required this.isOfficialMatch,
    required this.hasExpenses,
    this.estimatedCost,
    this.maxParticipants,
    required this.requiresConfirmation,
    this.confirmationDeadline,
    required this.requiresPaymentUpToDate,
    this.notes,
    this.metadata,
    this.postMatchVotingClosed = false,
    required this.participants,
    this.myParticipationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SportEvent.fromJson(Map<String, dynamic> json) {
    return SportEvent(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      type: SportEventType.fromString(json['type'] ?? 'training'),
      status: SportEventStatus.fromString(json['status'] ?? 'scheduled'),
      eventDate: DateTime.parse(json['eventDate'] ?? json['event_date']),
      durationMinutes: json['durationMinutes'] ?? json['duration_minutes'],
      location: json['location'],
      courtNumber: json['courtNumber'] ?? json['court_number'],
      teamId: json['teamId'] ?? json['team_id'],
      teamName: json['team']?['name'] ?? json['teamName'],
      createdBy: json['createdBy'] ?? json['created_by'],
      creatorName: json['creator']?['name'] ?? json['creatorName'],
      opponentName: json['opponentName'] ?? json['opponent_name'],
      isHomeMatch: json['isHomeMatch'] ?? json['is_home_match'] ?? true,
      isOfficialMatch:
          json['isOfficialMatch'] ?? json['is_official_match'] ?? false,
      hasExpenses: json['hasExpenses'] ?? json['has_expenses'] ?? false,
      estimatedCost: _parseDouble(json['estimatedCost'] ?? json['estimated_cost']),
      maxParticipants: json['maxParticipants'] ?? json['max_participants'],
      requiresConfirmation:
          json['requiresConfirmation'] ?? json['requires_confirmation'] ?? true,
      confirmationDeadline: json['confirmationDeadline'] != null
          ? DateTime.parse(json['confirmationDeadline'])
          : json['confirmation_deadline'] != null
              ? DateTime.parse(json['confirmation_deadline'])
              : null,
      requiresPaymentUpToDate: json['requiresPaymentUpToDate'] ??
          json['requires_payment_up_to_date'] ??
          false,
      notes: json['notes'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      postMatchVotingClosed: json['postMatchVotingClosed'] ==
              true ||
          json['post_match_voting_closed'] == true,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => EventParticipant.fromJson(p))
              .toList()
          : [],
      myParticipationStatus: json['myParticipation']?['status'] as String?,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'status': status.value,
      'eventDate': eventDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'location': location,
      'teamId': teamId,
      'createdBy': createdBy,
      'opponentName': opponentName,
      'isHomeMatch': isHomeMatch,
      'isOfficialMatch': isOfficialMatch,
      'hasExpenses': hasExpenses,
      'estimatedCost': estimatedCost,
      'maxParticipants': maxParticipants,
      'requiresConfirmation': requiresConfirmation,
      'confirmationDeadline': confirmationDeadline?.toIso8601String(),
      'requiresPaymentUpToDate': requiresPaymentUpToDate,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Participantes visibles en listados (en partidos, solo convocados).
  List<EventParticipant> get visibleParticipants {
    if (type != SportEventType.match) return participants;
    return participants.where((p) => p.isConvoked).toList();
  }

  // Getters computados
  int get participantCount => visibleParticipants.length;

  int get confirmedCount => visibleParticipants
      .where((p) => p.status == ParticipantStatus.confirmed)
      .length;

  int get pendingCount => visibleParticipants
      .where((p) => p.status == ParticipantStatus.pending)
      .length;

  int get declinedCount => visibleParticipants
      .where((p) => p.status == ParticipantStatus.declined)
      .length;

  bool get canDeleteConvocation =>
      type == SportEventType.match &&
      status == SportEventStatus.completed &&
      postMatchVotingClosed;

  String get typeDisplayName {
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

  String get statusDisplayName {
    switch (status) {
      case SportEventStatus.draft:
        return 'Borrador';
      case SportEventStatus.scheduled:
        return 'Programado';
      case SportEventStatus.confirmed:
        return 'Confirmado';
      case SportEventStatus.inProgress:
        return 'En progreso';
      case SportEventStatus.completed:
        return 'Completado';
      case SportEventStatus.cancelled:
        return 'Cancelado';
      case SportEventStatus.postponed:
        return 'Pospuesto';
    }
  }

  String get formattedDate {
    return '${eventDate.day.toString().padLeft(2, '0')}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.year} ${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}';
  }

  String get timeUntilEvent {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      return 'Evento pasado';
    } else if (difference.inDays > 0) {
      return 'En ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'En ${difference.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }

  bool get isUpcoming => eventDate.isAfter(DateTime.now());

  bool get isPast => eventDate.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  SportEvent copyWith({
    String? title,
    String? description,
    SportEventStatus? status,
    DateTime? eventDate,
    int? durationMinutes,
    String? location,
    String? opponentName,
    bool? isHomeMatch,
    bool? isOfficialMatch,
    bool? hasExpenses,
    double? estimatedCost,
    int? maxParticipants,
    bool? requiresConfirmation,
    DateTime? confirmationDeadline,
    bool? requiresPaymentUpToDate,
    String? notes,
    Map<String, dynamic>? metadata,
    List<EventParticipant>? participants,
  }) {
    return SportEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      status: status ?? this.status,
      eventDate: eventDate ?? this.eventDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      teamId: teamId,
      teamName: teamName,
      createdBy: createdBy,
      creatorName: creatorName,
      opponentName: opponentName ?? this.opponentName,
      isHomeMatch: isHomeMatch ?? this.isHomeMatch,
      isOfficialMatch: isOfficialMatch ?? this.isOfficialMatch,
      hasExpenses: hasExpenses ?? this.hasExpenses,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmationDeadline: confirmationDeadline ?? this.confirmationDeadline,
      requiresPaymentUpToDate:
          requiresPaymentUpToDate ?? this.requiresPaymentUpToDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      participants: participants ?? this.participants,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PlayerConvocationStats {
  final int userId;
  final int teamId;
  final int totalConvocations;
  final int timesConvoked;
  final int confirmed;
  final int declined;
  final int pending;
  final int noResponse;
  final double confirmationRate;
  final double responseRate;
  final List<PlayerConvocationRecent> recent;

  PlayerConvocationStats({
    required this.userId,
    required this.teamId,
    required this.totalConvocations,
    required this.timesConvoked,
    required this.confirmed,
    required this.declined,
    required this.pending,
    required this.noResponse,
    required this.confirmationRate,
    required this.responseRate,
    required this.recent,
  });

  factory PlayerConvocationStats.fromJson(Map<String, dynamic> json) {
    final recentList = json['recent'] as List<dynamic>? ?? [];
    return PlayerConvocationStats(
      userId: json['userId'] ?? 0,
      teamId: json['teamId'] ?? 0,
      totalConvocations: json['totalConvocations'] ?? 0,
      timesConvoked: json['timesConvoked'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      declined: json['declined'] ?? 0,
      pending: json['pending'] ?? 0,
      noResponse: json['noResponse'] ?? 0,
      confirmationRate: (json['confirmationRate'] as num?)?.toDouble() ?? 0,
      responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0,
      recent: recentList
          .map((e) => PlayerConvocationRecent.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

class PlayerConvocationRecent {
  final int eventId;
  final String title;
  final DateTime? eventDate;
  final String? opponentName;
  final bool isConvoked;
  final String status;

  PlayerConvocationRecent({
    required this.eventId,
    required this.title,
    this.eventDate,
    this.opponentName,
    required this.isConvoked,
    required this.status,
  });

  factory PlayerConvocationRecent.fromJson(Map<String, dynamic> json) {
    return PlayerConvocationRecent(
      eventId: json['eventId'] ?? 0,
      title: json['title'] ?? 'Partido',
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString())
          : null,
      opponentName: json['opponentName'],
      isConvoked: json['isConvoked'] == true,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmó';
      case 'declined':
        return 'Rechazó';
      case 'no_response':
        return 'Sin respuesta';
      default:
        return 'Pendiente';
    }
  }
}

import 'package:sportify_amateur/models/team.dart';

class PlayerRoster {
  final int id;
  final int playerId;
  final int teamId;
  final int jerseyNumber;
  final DateTime? medicalCertificateDate;
  final DateTime? medicalCertificateExpires;
  final bool isEnabled;
  final String position;
  final String documentNumber;
  final String? emergencyContact;
  final String season;
  final String category;
  final String medicalStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones
  final Player? player;
  final Team? team;

  PlayerRoster({
    required this.id,
    required this.playerId,
    required this.teamId,
    required this.jerseyNumber,
    this.medicalCertificateDate,
    this.medicalCertificateExpires,
    required this.isEnabled,
    required this.position,
    required this.documentNumber,
    this.emergencyContact,
    required this.season,
    required this.category,
    required this.medicalStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.player,
    this.team,
  });

  factory PlayerRoster.fromJson(Map<String, dynamic> json) {
    return PlayerRoster(
      id: json['id'] ?? 0,
      playerId: json['playerId'] ?? json['player_id'] ?? 0,
      teamId: json['teamId'] ?? json['team_id'] ?? 0,
      jerseyNumber: json['jerseyNumber'] ?? json['jersey_number'] ?? 0,
      medicalCertificateDate: json['medicalCertificateDate'] != null
          ? DateTime.parse(json['medicalCertificateDate'])
          : json['medical_certificate_date'] != null
              ? DateTime.parse(json['medical_certificate_date'])
              : null,
      medicalCertificateExpires: json['medicalCertificateExpires'] != null
          ? DateTime.parse(json['medicalCertificateExpires'])
          : json['medical_certificate_expires'] != null
              ? DateTime.parse(json['medical_certificate_expires'])
              : null,
      isEnabled: json['isEnabled'] ?? json['is_enabled'] ?? true,
      position: json['position'] ?? 'player',
      documentNumber: json['documentNumber'] ?? json['document_number'] ?? '',
      emergencyContact: json['emergencyContact'] ?? json['emergency_contact'],
      season: json['season'] ?? '',
      category: json['category'] ?? '',
      medicalStatus:
          json['medicalStatus'] ?? json['medical_status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
      player: json['player'] != null ? Player.fromJson(json['player']) : null,
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'teamId': teamId,
      'jerseyNumber': jerseyNumber,
      'medicalCertificateDate': medicalCertificateDate?.toIso8601String(),
      'medicalCertificateExpires': medicalCertificateExpires?.toIso8601String(),
      'isEnabled': isEnabled,
      'position': position,
      'documentNumber': documentNumber,
      'emergencyContact': emergencyContact,
      'season': season,
      'category': category,
      'medicalStatus': medicalStatus,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'player': player?.toJson(),
      'team': team?.toJson(),
    };
  }

  // Helpers
  String get playerName => player?.name ?? 'Jugador #$playerId';
  String get teamName => team?.name ?? 'Equipo #$teamId';

  bool get isMedicalCertificateValid {
    if (medicalCertificateExpires == null) return false;
    return medicalCertificateExpires!.isAfter(DateTime.now());
  }

  bool get canPlay =>
      isEnabled && medicalStatus == 'approved' && isMedicalCertificateValid;

  String get positionDisplayName {
    switch (position) {
      case 'goalkeeper':
        return 'Arquero';
      case 'defender':
        return 'Defensor';
      case 'midfielder':
        return 'Mediocampo';
      case 'forward':
        return 'Delantero';
      default:
        return 'Jugador';
    }
  }

  String get medicalStatusDisplayName {
    switch (medicalStatus) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'expired':
        return 'Vencido';
      case 'rejected':
        return 'Rechazado';
      default:
        return 'Desconocido';
    }
  }
}

// Necesitamos importar estos modelos
class Player {
  final int id;
  final String name;
  final String? email;

  Player({required this.id, required this.name, this.email});

  factory Player.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? 0;
    return Player(
      id: id,
      name: json['user']?['username'] ?? json['name'] ?? 'Jugador $id',
      email: json['user']?['email'] ?? json['email'],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

// Usar Team del servicio importado

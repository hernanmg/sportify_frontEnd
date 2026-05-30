import 'package:flutter/material.dart';

enum EligibilityStatus {
  eligible('eligible'),
  feeUnpaid('fee_unpaid'),
  noMedical('no_medical'),
  injured('injured'),
  suspended('suspended'),
  other('other'),
  disabled('disabled');

  const EligibilityStatus(this.value);
  final String value;

  static EligibilityStatus fromString(String? v) {
    return EligibilityStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => EligibilityStatus.eligible,
    );
  }
}

enum EligibilityColor {
  green('green'),
  red('red'),
  orange('orange'),
  yellow('yellow');

  const EligibilityColor(this.value);
  final String value;

  static EligibilityColor fromString(String? v) {
    return EligibilityColor.values.firstWhere(
      (e) => e.value == v,
      orElse: () => EligibilityColor.green,
    );
  }

  Color get materialColor {
    switch (this) {
      case EligibilityColor.green:
        return Colors.green;
      case EligibilityColor.red:
        return Colors.red;
      case EligibilityColor.orange:
        return Colors.orange;
      case EligibilityColor.yellow:
        return Colors.amber;
    }
  }
}

class PlayerEligibility {
  final int userId;
  final String playerName;
  final String? avatarUrl;
  final int? jerseyNumber;
  final String? position;
  final String? category;
  final EligibilityStatus status;
  final String statusLabel;
  final String reason;
  final EligibilityColor color;
  final int? daysRemaining;
  final String? endDate;
  final double? feeBalance;
  final FeeOverrideInfo? feeOverride;
  final int? activeImpedimentId;

  PlayerEligibility({
    required this.userId,
    required this.playerName,
    this.avatarUrl,
    this.jerseyNumber,
    this.position,
    this.category,
    required this.status,
    required this.statusLabel,
    required this.reason,
    required this.color,
    this.daysRemaining,
    this.endDate,
    this.feeBalance,
    this.feeOverride,
    this.activeImpedimentId,
  });

  bool get isEligible => status == EligibilityStatus.eligible;

  String get statusEmoji {
    switch (status) {
      case EligibilityStatus.eligible:
        return '✅';
      case EligibilityStatus.feeUnpaid:
        return '❌';
      case EligibilityStatus.noMedical:
        return '❌';
      case EligibilityStatus.injured:
        return '🟠';
      case EligibilityStatus.suspended:
        return '🟠';
      case EligibilityStatus.other:
        return '🟡';
      case EligibilityStatus.disabled:
        return '❌';
    }
  }

  factory PlayerEligibility.fromJson(Map<String, dynamic> json) {
    return PlayerEligibility(
      userId: json['userId'] as int,
      playerName: json['playerName']?.toString() ?? 'Jugador',
      avatarUrl: json['avatarUrl']?.toString(),
      jerseyNumber: json['jerseyNumber'] as int?,
      position: json['position'] as String?,
      category: json['category'] as String?,
      status: EligibilityStatus.fromString(json['status'] as String?),
      statusLabel: json['statusLabel']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      color: EligibilityColor.fromString(json['color'] as String?),
      daysRemaining: json['daysRemaining'] as int?,
      endDate: json['endDate'] as String?,
      feeBalance: json['feeBalance'] != null
          ? (json['feeBalance'] as num).toDouble()
          : null,
      feeOverride: json['feeOverride'] != null
          ? FeeOverrideInfo.fromJson(
              Map<String, dynamic>.from(json['feeOverride'] as Map),
            )
          : null,
      activeImpedimentId: json['activeImpedimentId'] as int?,
    );
  }
}

class FeeOverrideInfo {
  final int overriddenBy;
  final String overriddenAt;
  final String? reason;

  FeeOverrideInfo({
    required this.overriddenBy,
    required this.overriddenAt,
    this.reason,
  });

  factory FeeOverrideInfo.fromJson(Map<String, dynamic> json) {
    return FeeOverrideInfo(
      overriddenBy: json['overriddenBy'] as int,
      overriddenAt: json['overriddenAt']?.toString() ?? '',
      reason: json['reason'] as String?,
    );
  }
}

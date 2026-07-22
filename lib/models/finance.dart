class FeeCharge {
  final int id;
  final int teamId;
  final int userId;
  final String type;
  final String concept;
  final double amount;
  final double paidAmount;
  final String status;
  final String? dueDate;
  final String? season;
  final String? userName;

  FeeCharge({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.type,
    required this.concept,
    required this.amount,
    required this.paidAmount,
    required this.status,
    this.dueDate,
    this.season,
    this.userName,
  });

  double get pendingAmount => (amount - paidAmount).clamp(0, amount);

  /// Período de la cuota en formato MM/aaaa (p. ej. 08/2026).
  String? get periodLabel => feeChargePeriodLabel(
        dueDate: dueDate,
        concept: concept,
      );

  factory FeeCharge.fromJson(Map<String, dynamic> json) {
    return FeeCharge(
      id: json['id'] as int,
      teamId: json['teamId'] as int,
      userId: json['userId'] as int,
      type: json['type'] as String? ?? 'monthly_quota',
      concept: json['concept'] as String? ?? '',
      amount: _toDouble(json['amount']),
      paidAmount: _toDouble(json['paidAmount']),
      status: json['status'] as String? ?? 'pending',
      dueDate: json['dueDate']?.toString(),
      season: json['season'] as String?,
      userName: _userNameFromJson(json['user']) ?? json['userName']?.toString(),
    );
  }
}

class PlayerPayment {
  final int id;
  final int teamId;
  final int userId;
  final double amount;
  final String method;
  final String status;
  final String? notes;
  final String? createdAt;
  final String? rejectionReason;
  final String? userName;
  final bool hasReceipt;
  final String? receiptMimeType;

  PlayerPayment({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.notes,
    this.createdAt,
    this.rejectionReason,
    this.userName,
    this.hasReceipt = false,
    this.receiptMimeType,
  });

  bool get isPending => status == 'pending_confirmation';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';

  String get statusLabel => paymentStatusLabel(status);

  factory PlayerPayment.fromJson(Map<String, dynamic> json) {
    return PlayerPayment(
      id: json['id'] as int,
      teamId: json['teamId'] as int,
      userId: json['userId'] as int,
      amount: _toDouble(json['amount']),
      method: json['method'] as String? ?? 'transfer',
      status: json['status'] as String? ?? 'confirmed',
      notes: json['notes'] as String?,
      createdAt: json['createdAt']?.toString(),
      rejectionReason: json['rejectionReason'] as String?,
      userName: _userNameFromJson(json['user']),
      hasReceipt: json['hasReceipt'] == true || json['receiptPath'] != null,
      receiptMimeType: json['receiptMimeType'] as String?,
    );
  }
}

class LedgerEntry {
  final int id;
  final int teamId;
  final String type;
  final String category;
  final double amount;
  final String description;
  final int? userId;
  final String? createdAt;

  LedgerEntry({
    required this.id,
    required this.teamId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    this.userId,
    this.createdAt,
  });

  bool get isIncome => type == 'income';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as int,
      teamId: json['teamId'] as int,
      type: json['type'] as String,
      category: json['category'] as String? ?? 'other',
      amount: _toDouble(json['amount']),
      description: json['description'] as String? ?? '',
      userId: json['userId'] as int?,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class MyAccountSummary {
  final int userId;
  final int? teamId;
  final double totalCharged;
  final double totalPaid;
  final double balance;
  final List<FeeCharge> charges;
  final List<PlayerPayment> payments;
  final List<PlayerPayment> pendingPayments;

  MyAccountSummary({
    required this.userId,
    this.teamId,
    required this.totalCharged,
    required this.totalPaid,
    required this.balance,
    required this.charges,
    required this.payments,
    required this.pendingPayments,
  });

  factory MyAccountSummary.fromJson(Map<String, dynamic> json) {
    return MyAccountSummary(
      userId: json['userId'] as int,
      teamId: json['teamId'] as int?,
      totalCharged: _toDouble(json['totalCharged']),
      totalPaid: _toDouble(json['totalPaid']),
      balance: _toDouble(json['balance']),
      charges: (json['charges'] as List<dynamic>? ?? [])
          .map((e) => FeeCharge.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => PlayerPayment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      pendingPayments: (json['pendingPayments'] as List<dynamic>? ?? [])
          .map((e) => PlayerPayment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class TeamFinanceSummary {
  final int teamId;
  final double cashBalance;
  final double totalIncome;
  final double totalExpenses;
  final double totalOutstanding;
  final int pendingPaymentsCount;

  TeamFinanceSummary({
    required this.teamId,
    required this.cashBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalOutstanding,
    required this.pendingPaymentsCount,
  });

  factory TeamFinanceSummary.fromJson(Map<String, dynamic> json) {
    return TeamFinanceSummary(
      teamId: json['teamId'] as int,
      cashBalance: _toDouble(json['cashBalance']),
      totalIncome: _toDouble(json['totalIncome']),
      totalExpenses: _toDouble(json['totalExpenses']),
      totalOutstanding: _toDouble(json['totalOutstanding']),
      pendingPaymentsCount: json['pendingPaymentsCount'] as int? ?? 0,
    );
  }
}

class PlayerBalance {
  final int userId;
  final String userName;
  final double totalCharged;
  final double totalPaid;
  final double balance;
  final int? jerseyNumber;

  PlayerBalance({
    required this.userId,
    required this.userName,
    required this.totalCharged,
    required this.totalPaid,
    required this.balance,
    this.jerseyNumber,
  });

  factory PlayerBalance.fromJson(Map<String, dynamic> json) {
    return PlayerBalance(
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? 'Jugador',
      totalCharged: _toDouble(json['totalCharged']),
      totalPaid: _toDouble(json['totalPaid']),
      balance: _toDouble(json['balance']),
      jerseyNumber: json['jerseyNumber'] as int?,
    );
  }

  String get displayLabel {
    final jersey = jerseyNumber != null ? ' #$jerseyNumber' : '';
    return '$userName$jersey (${formatMoney(balance)})';
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String formatMoney(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

String paymentStatusLabel(String status) {
  switch (status) {
    case 'pending_confirmation':
      return 'Pendiente de confirmación';
    case 'confirmed':
      return 'Confirmado';
    case 'rejected':
      return 'Rechazado';
    default:
      return status;
  }
}

String paymentMethodLabel(String method) {
  switch (method) {
    case 'cash':
      return 'Efectivo';
    case 'transfer':
      return 'Transferencia';
    case 'mercadopago':
      return 'Mercado Pago';
    default:
      return 'Otro';
  }
}

String? feeChargePeriodLabel({String? dueDate, String? concept}) {
  if (dueDate != null && dueDate.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(dueDate);
    if (parsed != null) {
      final mm = parsed.month.toString().padLeft(2, '0');
      return '$mm/${parsed.year}';
    }
  }
  if (concept == null || concept.trim().isEmpty) return null;
  final match = RegExp(
    r'cuota\s+(\w+)\s+(\d{4})',
    caseSensitive: false,
  ).firstMatch(concept);
  if (match == null) return null;
  const monthNames = {
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'septiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
  };
  final month = monthNames[match.group(1)!.toLowerCase()];
  final year = match.group(2);
  if (month == null || year == null) return null;
  return '${month.toString().padLeft(2, '0')}/$year';
}

String? _userNameFromJson(dynamic user) {
  if (user is! Map) return null;
  final map = Map<String, dynamic>.from(user);
  final first = map['firstName'] ?? map['first_name'];
  final last = map['lastName'] ?? map['last_name'];
  final combined = [first, last]
      .where((part) => part != null && part.toString().trim().isNotEmpty)
      .map((part) => part.toString())
      .join(' ')
      .trim();
  if (combined.isNotEmpty) return combined;
  return map['username']?.toString();
}

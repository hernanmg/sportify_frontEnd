class EventExpenseItem {
  final int id;
  final String description;
  final double amount;
  final int paidByUserId;
  final String paidByName;
  final int? createdBy;

  EventExpenseItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidByUserId,
    required this.paidByName,
    this.createdBy,
  });

  factory EventExpenseItem.fromJson(Map<String, dynamic> json) {
    return EventExpenseItem(
      id: json['id'] as int,
      description: json['description'] as String? ?? '',
      amount: _toDouble(json['amount']),
      paidByUserId: json['paidByUserId'] as int? ?? json['paid_by_user_id'] as int,
      paidByName: _userNameFromJson(json['paidBy']) ?? 'Usuario',
      createdBy: json['createdBy'] as int?,
    );
  }
}

class ParticipantBalance {
  final int userId;
  final String userName;
  final double totalPaid;
  final double shareOwed;
  final double netBalance;

  ParticipantBalance({
    required this.userId,
    required this.userName,
    required this.totalPaid,
    required this.shareOwed,
    required this.netBalance,
  });

  factory ParticipantBalance.fromJson(Map<String, dynamic> json) {
    return ParticipantBalance(
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? 'Usuario',
      totalPaid: _toDouble(json['totalPaid']),
      shareOwed: _toDouble(json['shareOwed']),
      netBalance: _toDouble(json['netBalance']),
    );
  }

  bool get isCreditor => netBalance > 0.01;
  bool get isDebtor => netBalance < -0.01;
}

class EventExpenseSettlement {
  final int fromUserId;
  final String fromUserName;
  final int toUserId;
  final String toUserName;
  final double amount;

  EventExpenseSettlement({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  factory EventExpenseSettlement.fromJson(Map<String, dynamic> json) {
    return EventExpenseSettlement(
      fromUserId: json['fromUserId'] as int,
      fromUserName: json['fromUserName'] as String? ?? '',
      toUserId: json['toUserId'] as int,
      toUserName: json['toUserName'] as String? ?? '',
      amount: _toDouble(json['amount']),
    );
  }
}

class EventExpenseParticipantOption {
  final int userId;
  final String userName;
  final String status;
  final bool includedInExpenseSplit;

  EventExpenseParticipantOption({
    required this.userId,
    required this.userName,
    required this.status,
    this.includedInExpenseSplit = true,
  });

  factory EventExpenseParticipantOption.fromJson(Map<String, dynamic> json) {
    return EventExpenseParticipantOption(
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? 'Usuario',
      status: json['status'] as String? ?? 'pending',
      includedInExpenseSplit:
          json['includedInExpenseSplit'] as bool? ?? true,
    );
  }

  bool get isDeclined => status == 'declined';

  bool get isConfirmed => status == 'confirmed';

  bool get canToggleExpenseSplit => isConfirmed && !isDeclined;
}

class EventExpenseSheetView {
  final int eventId;
  final int teamId;
  final String eventTitle;
  final double itemsTotal;
  final String splitMode;
  final List<EventExpenseParticipantOption> participants;
  final List<EventExpenseItem> items;
  final List<ParticipantBalance> balances;
  final List<EventExpenseSettlement> settlements;

  EventExpenseSheetView({
    required this.eventId,
    required this.teamId,
    required this.eventTitle,
    required this.itemsTotal,
    required this.splitMode,
    required this.participants,
    required this.items,
    required this.balances,
    required this.settlements,
  });

  factory EventExpenseSheetView.fromJson(Map<String, dynamic> json) {
    final event = Map<String, dynamic>.from(json['event'] as Map);
    final sheet = json['sheet'];
    List<EventExpenseItem> items = [];
    if (sheet is Map) {
      items = (sheet['items'] as List<dynamic>? ?? [])
          .map((e) => EventExpenseItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return EventExpenseSheetView(
      eventId: event['id'] as int,
      teamId: event['teamId'] as int? ?? 0,
      eventTitle: event['title'] as String? ?? '',
      itemsTotal: _toDouble(json['itemsTotal']),
      splitMode: json['splitMode'] as String? ?? 'equal',
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((e) => EventExpenseParticipantOption.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      items: items,
      balances: (json['balances'] as List<dynamic>? ?? [])
          .map((e) => ParticipantBalance.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      settlements: (json['settlements'] as List<dynamic>? ?? [])
          .map((e) => EventExpenseSettlement.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String formatEventMoney(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
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

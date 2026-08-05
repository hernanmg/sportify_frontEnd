import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/finance.dart';

class FinanceService {
  final Dio _dio = DioClient.instance;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is List) {
          return message.map((item) => item.toString()).join('\n');
        }
        if (message != null) return message.toString();
      }
    }
    return error.toString();
  }

  Future<MyAccountSummary> getMyAccount({int? teamId}) async {
    final response = await _dio.get(
      '/finance/my-account',
      queryParameters: teamId != null ? {'teamId': teamId} : null,
    );
    return MyAccountSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<TeamFinanceSummary> getTeamSummary(int teamId) async {
    final response = await _dio.get('/finance/team/$teamId/summary');
    return TeamFinanceSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<PlayerBalance>> getTeamPlayerBalances(
    int teamId, {
    String? season,
    int? categoryId,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (season != null) queryParameters['season'] = season;
    if (categoryId != null) queryParameters['categoryId'] = categoryId;
    final response = await _dio.get(
      '/finance/team/$teamId/players-balance',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PlayerBalance.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<LedgerEntry>> getTeamLedger(int teamId, {int limit = 50}) async {
    final response = await _dio.get(
      '/finance/team/$teamId/ledger',
      queryParameters: {'limit': limit},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<FeeCharge>> getTeamCharges(int teamId, {String? status}) async {
    final response = await _dio.get(
      '/finance/team/$teamId/charges',
      queryParameters: status != null ? {'status': status} : null,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => FeeCharge.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> generateFeeBatch({
    required int teamId,
    required String concept,
    required double amount,
    String? dueDate,
    String? season,
  }) async {
    final response = await _dio.post('/finance/fees/batch', data: {
      'teamId': teamId,
      'concept': concept,
      'amount': amount,
      if (dueDate != null) 'dueDate': dueDate,
      if (season != null) 'season': season,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> registerPayment({
    required int teamId,
    required int userId,
    required double amount,
    String method = 'transfer',
    String? notes,
    List<int>? feeChargeIds,
  }) async {
    final response = await _dio.post('/finance/payments', data: {
      'teamId': teamId,
      'userId': userId,
      'amount': amount,
      'method': method,
      if (notes != null) 'notes': notes,
      if (feeChargeIds != null) 'feeChargeIds': feeChargeIds,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<PlayerPayment> submitPayment({
    required int teamId,
    required double amount,
    String method = 'transfer',
    String? notes,
    List<int>? feeChargeIds,
    XFile? receipt,
  }) async {
    if (receipt != null) {
      final bytes = await receipt.readAsBytes();
      final filename = receipt.name.isNotEmpty ? receipt.name : 'comprobante.jpg';
      final formData = FormData.fromMap({
        'teamId': teamId.toString(),
        'amount': amount.toString(),
        'method': method,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (feeChargeIds != null && feeChargeIds.isNotEmpty)
          'feeChargeIds': jsonEncode(feeChargeIds),
        'receipt': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        '/finance/payments/submit',
        data: formData,
      );
      return PlayerPayment.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }

    final response = await _dio.post('/finance/payments/submit', data: {
      'teamId': teamId,
      'amount': amount,
      'method': method,
      if (notes != null) 'notes': notes,
      if (feeChargeIds != null) 'feeChargeIds': feeChargeIds,
    });
    return PlayerPayment.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Uint8List?> fetchPaymentReceipt(int paymentId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/finance/payments/$paymentId/receipt',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null) return null;
      return Uint8List.fromList(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<PlayerPayment>> getPendingPayments(int teamId) async {
    final response = await _dio.get('/finance/team/$teamId/payments/pending');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PlayerPayment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> confirmPayment(int paymentId) async {
    final response = await _dio.patch('/finance/payments/$paymentId/confirm');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<PlayerPayment> rejectPayment(int paymentId, {String? reason}) async {
    final response = await _dio.patch(
      '/finance/payments/$paymentId/reject',
      data: reason != null ? {'reason': reason} : null,
    );
    return PlayerPayment.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<LedgerEntry> createTeamExpense({
    required int teamId,
    required double amount,
    required String description,
    String category = 'other',
  }) async {
    final response = await _dio.post('/finance/expenses', data: {
      'teamId': teamId,
      'amount': amount,
      'description': description,
      'category': category,
    });
    return LedgerEntry.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> generateMonthlyQuota({
    required int teamId,
    required int year,
    required int month,
    required double amount,
    String? season,
  }) async {
    final response = await _dio.post('/finance/fees/monthly-quota', data: {
      'teamId': teamId,
      'year': year,
      'month': month,
      'amount': amount,
      if (season != null) 'season': season,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> generateRecurringMonthlyQuota({
    required int teamId,
    required int year,
    required int month,
    required double amount,
    required int monthCount,
    String? season,
  }) async {
    final response = await _dio.post(
      '/finance/fees/monthly-quota/recurring',
      data: {
        'teamId': teamId,
        'year': year,
        'month': month,
        'amount': amount,
        'monthCount': monthCount,
        if (season != null) 'season': season,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<QuotaSeries>> listQuotaSeries(int teamId) async {
    final response = await _dio.get('/finance/team/$teamId/quota-series');
    final data = response.data as List<dynamic>;
    return data
        .map((e) => QuotaSeries.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateQuotaSeries(String groupId, double amount) async {
    await _dio.patch(
      '/finance/fees/quota-series/$groupId',
      data: {'amount': amount},
    );
  }

  Future<Map<String, dynamic>> deleteQuotaSeries(String groupId) async {
    final response = await _dio.delete('/finance/fees/quota-series/$groupId');
    return Map<String, dynamic>.from(response.data as Map? ?? {});
  }

  Future<FeeCharge> updateFeeCharge(
    int chargeId, {
    double? amount,
    String? concept,
    String? dueDate,
    String? status,
  }) async {
    final response = await _dio.patch(
      '/finance/fees/$chargeId',
      data: {
        if (amount != null) 'amount': amount,
        if (concept != null) 'concept': concept,
        if (dueDate != null) 'dueDate': dueDate,
        if (status != null) 'status': status,
      },
    );
    return FeeCharge.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteFeeCharge(int chargeId) async {
    await _dio.delete('/finance/fees/$chargeId');
  }

  Future<Map<String, dynamic>> closeCashRegister({
    required int teamId,
    bool carryPendingQuotas = true,
    bool resetCashToZero = true,
    String? season,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/finance/team/$teamId/cash-close',
      data: {
        'carryPendingQuotas': carryPendingQuotas,
        'resetCashToZero': resetCashToZero,
        if (season != null) 'season': season,
        if (notes != null) 'notes': notes,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> resetCashToZero({
    required int teamId,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/finance/team/$teamId/cash-zero',
      data: {if (notes != null) 'notes': notes},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<QuotaOverview> getQuotaOverview(
    int teamId, {
    String? concept,
    String? season,
    int? categoryId,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (concept != null) queryParameters['concept'] = concept;
    if (season != null) queryParameters['season'] = season;
    if (categoryId != null) queryParameters['categoryId'] = categoryId;
    final response = await _dio.get(
      '/finance/team/$teamId/quota-overview',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return QuotaOverview.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> sendQuotaReminders(
    int teamId, {
    String? concept,
  }) async {
    final response = await _dio.post(
      '/finance/team/$teamId/quota-reminders',
      queryParameters: concept != null ? {'concept': concept} : null,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<TrainingCollectionView> getTrainingCollection(int eventId) async {
    final response =
        await _dio.get('/finance/sport-events/$eventId/training-collection');
    return TrainingCollectionView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Map<String, dynamic>> openTrainingCollection(
    int eventId, {
    required double amountPerPlayer,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/finance/sport-events/$eventId/training-collection',
      data: {
        'amountPerPlayer': amountPerPlayer,
        if (notes != null) 'notes': notes,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<LedgerEntry> createTrainingExpense({
    required int teamId,
    required int sportEventId,
    required double amount,
    required String description,
  }) async {
    final response = await _dio.post('/finance/training-expenses', data: {
      'teamId': teamId,
      'sportEventId': sportEventId,
      'amount': amount,
      'description': description,
    });
    return LedgerEntry.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class QuotaOverview {
  final int teamId;
  final String? concept;
  final double totalCharged;
  final double totalPaid;
  final double totalOutstanding;
  final int playersCount;
  final int paidCount;
  final int pendingCount;
  final List<QuotaPlayerRow> players;

  QuotaOverview({
    required this.teamId,
    this.concept,
    required this.totalCharged,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.playersCount,
    required this.paidCount,
    required this.pendingCount,
    required this.players,
  });

  factory QuotaOverview.fromJson(Map<String, dynamic> json) {
    return QuotaOverview(
      teamId: json['teamId'] as int,
      concept: json['concept']?.toString(),
      totalCharged: _parseAmount(json['totalCharged']),
      totalPaid: _parseAmount(json['totalPaid']),
      totalOutstanding: _parseAmount(json['totalOutstanding']),
      playersCount: json['playersCount'] as int? ?? 0,
      paidCount: json['paidCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      players: (json['players'] as List<dynamic>? ?? [])
          .map((e) => QuotaPlayerRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class QuotaPlayerRow {
  final int userId;
  final String userName;
  final double totalCharged;
  final double totalPaid;
  final double balance;
  final String status;

  QuotaPlayerRow({
    required this.userId,
    required this.userName,
    required this.totalCharged,
    required this.totalPaid,
    required this.balance,
    required this.status,
  });

  factory QuotaPlayerRow.fromJson(Map<String, dynamic> json) {
    return QuotaPlayerRow(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
      totalCharged: _parseAmount(json['totalCharged']),
      totalPaid: _parseAmount(json['totalPaid']),
      balance: _parseAmount(json['balance']),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  bool get isPaid => balance <= 0.01;
}

class QuotaSeries {
  final String recurringGroupId;
  final double amount;
  final List<String> concepts;
  final int chargeCount;
  final int pendingCount;
  final int paidCount;
  final String? startDueDate;
  final String? endDueDate;

  QuotaSeries({
    required this.recurringGroupId,
    required this.amount,
    required this.concepts,
    required this.chargeCount,
    required this.pendingCount,
    required this.paidCount,
    this.startDueDate,
    this.endDueDate,
  });

  factory QuotaSeries.fromJson(Map<String, dynamic> json) {
    return QuotaSeries(
      recurringGroupId: json['recurringGroupId']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      concepts: (json['concepts'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      chargeCount: json['chargeCount'] as int? ?? 0,
      pendingCount: json['pendingCount'] as int? ?? 0,
      paidCount: json['paidCount'] as int? ?? 0,
      startDueDate: json['startDueDate']?.toString(),
      endDueDate: json['endDueDate']?.toString(),
    );
  }

  int get monthSpan => concepts.length;
}

class TrainingCollectionView {
  final int eventId;
  final int teamId;
  final String title;
  final double totalExpense;
  final int confirmedCount;
  final double? amountPerPlayer;
  final List<TrainingExpenseRow> expenses;
  final List<TrainingCollectionPlayer> players;
  final TrainingCollectionSummary summary;

  TrainingCollectionView({
    required this.eventId,
    required this.teamId,
    required this.title,
    required this.totalExpense,
    required this.confirmedCount,
    this.amountPerPlayer,
    required this.expenses,
    required this.players,
    required this.summary,
  });

  factory TrainingCollectionView.fromJson(Map<String, dynamic> json) {
    return TrainingCollectionView(
      eventId: json['eventId'] as int,
      teamId: json['teamId'] as int,
      title: json['title']?.toString() ?? '',
      totalExpense: _parseAmount(json['totalExpense']),
      confirmedCount: json['confirmedCount'] as int? ?? 0,
      amountPerPlayer: json['amountPerPlayer'] != null
          ? _parseAmount(json['amountPerPlayer'])
          : null,
      expenses: (json['expenses'] as List<dynamic>? ?? [])
          .map(
            (e) => TrainingExpenseRow.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      players: (json['players'] as List<dynamic>? ?? [])
          .map(
            (e) => TrainingCollectionPlayer.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      summary: TrainingCollectionSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
      ),
    );
  }

  bool get isOpen => players.isNotEmpty || totalExpense > 0;
}

class TrainingExpenseRow {
  final int id;
  final double amount;
  final String description;

  TrainingExpenseRow({
    required this.id,
    required this.amount,
    required this.description,
  });

  factory TrainingExpenseRow.fromJson(Map<String, dynamic> json) {
    return TrainingExpenseRow(
      id: json['id'] as int,
      amount: _parseAmount(json['amount']),
      description: json['description']?.toString() ?? '',
    );
  }
}

class TrainingCollectionPlayer {
  final int userId;
  final String userName;
  final int? chargeId;
  final double amount;
  final double paidAmount;
  final String status;
  final double balance;

  TrainingCollectionPlayer({
    required this.userId,
    required this.userName,
    this.chargeId,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.balance,
  });

  factory TrainingCollectionPlayer.fromJson(Map<String, dynamic> json) {
    return TrainingCollectionPlayer(
      userId: json['userId'] as int,
      userName: json['userName']?.toString() ?? '',
      chargeId: json['chargeId'] as int?,
      amount: _parseAmount(json['amount']),
      paidAmount: _parseAmount(json['paidAmount']),
      status: json['status']?.toString() ?? 'pending',
      balance: _parseAmount(json['balance']),
    );
  }

  bool get isPaid => balance <= 0.01;
}

class TrainingCollectionSummary {
  final int total;
  final int paid;
  final int pending;

  TrainingCollectionSummary({
    required this.total,
    required this.paid,
    required this.pending,
  });

  factory TrainingCollectionSummary.fromJson(Map<String, dynamic> json) {
    return TrainingCollectionSummary(
      total: json['total'] as int? ?? 0,
      paid: json['paid'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
    );
  }
}

double _parseAmount(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

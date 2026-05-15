import 'package:dio/dio.dart';
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
  }) async {
    final response = await _dio.get(
      '/finance/team/$teamId/players-balance',
      queryParameters: season != null ? {'season': season} : null,
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
  }) async {
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
}

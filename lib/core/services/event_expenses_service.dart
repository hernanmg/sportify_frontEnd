import 'package:dio/dio.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/models/event_expense_sheet.dart';

class EventExpensesService {
  final Dio _dio = DioClient.instance;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'];
        if (message is List) {
          return message.map((e) => e.toString()).join('\n');
        }
        if (message != null) return message.toString();
      }
    }
    return error.toString();
  }

  Future<EventExpenseSheetView> getSheet(int eventId) async {
    final response = await _dio.get('/sport-events/$eventId/expense-sheet');
    return EventExpenseSheetView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<EventExpenseSheetView> addItem({
    required int eventId,
    required String description,
    required double amount,
    int? paidByUserId,
  }) async {
    final response = await _dio.post(
      '/sport-events/$eventId/expense-items',
      data: {
        'description': description,
        'amount': amount,
        if (paidByUserId != null) 'paidByUserId': paidByUserId,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['sheet'] != null) {
      return EventExpenseSheetView.fromJson(
        Map<String, dynamic>.from(data['sheet'] as Map),
      );
    }
    return getSheet(eventId);
  }

  Future<EventExpenseSheetView> deleteItem({
    required int eventId,
    required int itemId,
  }) async {
    final response = await _dio.delete(
      '/sport-events/$eventId/expense-items/$itemId',
    );
    return EventExpenseSheetView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<EventExpenseSheetView> updateSplitMode({
    required int eventId,
    required String splitMode,
  }) async {
    final response = await _dio.patch(
      '/sport-events/$eventId/expense-sheet/split-mode',
      data: {'splitMode': splitMode},
    );
    return EventExpenseSheetView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<EventExpenseSheetView> updateManualShares({
    required int eventId,
    required List<Map<String, dynamic>> shares,
  }) async {
    final response = await _dio.patch(
      '/sport-events/$eventId/expense-sheet/shares',
      data: {'shares': shares},
    );
    return EventExpenseSheetView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<Map<String, dynamic>>> getSocialGuests(int eventId) async {
    final response = await _dio.get('/sport-events/$eventId/social-guests');
    final data = response.data as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<EventExpenseSheetView> addSocialGuest({
    required int eventId,
    required String displayName,
    String? phone,
    String? email,
  }) async {
    await _dio.post(
      '/sport-events/$eventId/guest-participants',
      data: {
        'displayName': displayName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    return getSheet(eventId);
  }

  Future<EventExpenseSheetView> setParticipantInSplit({
    required int eventId,
    required int userId,
    required bool included,
  }) async {
    final response = await _dio.patch(
      '/sport-events/$eventId/participants/$userId/expense-inclusion',
      data: {'includedInExpenseSplit': included},
    );
    return EventExpenseSheetView.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

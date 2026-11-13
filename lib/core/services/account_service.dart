import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_amateur/core/common/active_workspace_provider.dart';
import 'package:sportify_amateur/core/common/dio_client.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/biometric_auth_service.dart';
import 'package:sportify_amateur/core/utils/api_error_messages.dart';

class AccountService {
  final Dio _dio = DioClient.instance;

  Future<void> deleteOwnAccount({String? password}) async {
    try {
      await _dio.delete('/users/me', data: {
        if (password != null && password.isNotEmpty) 'password': password,
      });
    } on DioException catch (e) {
      throw Exception(ApiErrorMessages.from(e));
    }
  }

  /// Limpia sesión local (push, tokens, workspace) y vuelve al login.
  static Future<void> logoutAndGoToLogin(
    BuildContext context, {
    bool disableBiometric = false,
  }) async {
    final navigator = Navigator.of(context);
    ActiveWorkspaceProvider? workspace;
    try {
      workspace = context.read<ActiveWorkspaceProvider>();
    } catch (_) {}

    if (disableBiometric) {
      final userId = await AuthStorageService().getUserId();
      if (userId != null) {
        await BiometricAuthService.instance.setEnabledForUser(userId, false);
      }
    }
    await workspace?.clear();
    await AuthService().signOut();
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

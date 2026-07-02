import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/biometric_auth_service.dart';

/// Arranque: sesión guardada y opcionalmente biometría antes del dashboard.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  final _auth = AuthService();
  final _storage = AuthStorageService();
  final _biometric = BiometricAuthService.instance;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _bootstrapInner().timeout(const Duration(seconds: 45));
    } catch (_) {
      _goLogin();
    }
  }

  Future<void> _bootstrapInner() async {
    final token = await _storage.getToken();
    if (token == null) {
      _goLogin();
      return;
    }

    final userId = await _storage.getUserId();
    if (userId != null &&
        await _biometric.isEnabledForUser(userId) &&
        await _biometric.isBiometricUnlockAvailable()) {
      final ok = await _biometric
          .authenticate()
          .timeout(const Duration(seconds: 90), onTimeout: () => false);
      if (!ok) {
        _goLogin();
        return;
      }
    }

    final status = await _auth.checkAuthStatus().timeout(
          const Duration(seconds: 45),
          onTimeout: () => {'isAuthenticated': false},
        );
    if (!mounted) return;
    if (status['isAuthenticated'] == true) {
      await _auth.navigateAfterAuth(context).timeout(
            const Duration(seconds: 45),
            onTimeout: () {},
          );
    } else {
      _goLogin();
    }
  }

  void _goLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 56),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando Sportify Amateur…'),
          ],
        ),
      ),
    );
  }
}

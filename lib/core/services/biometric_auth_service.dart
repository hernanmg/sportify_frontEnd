import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Desbloqueo con huella / Face ID para cualquier usuario con sesión guardada.
class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _enabledKey(String userId) => 'biometric_enabled_$userId';

  Future<bool> isBiometricUnlockAvailable() async {
    if (kIsWeb) return false;
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      final types = await _localAuth.getAvailableBiometrics();
      if (types.isNotEmpty) return true;
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  String biometricLabel(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'huella digital';
    if (types.contains(BiometricType.strong) ||
        types.contains(BiometricType.weak)) {
      return 'biometría';
    }
    return 'biometría';
  }

  Future<bool> isEnabledForUser(String userId) async {
    final v = await _storage.read(key: _enabledKey(userId));
    return v == 'true';
  }

  Future<void> setEnabledForUser(String userId, bool enabled) async {
    if (enabled) {
      await _storage.write(key: _enabledKey(userId), value: 'true');
    } else {
      await _storage.delete(key: _enabledKey(userId));
    }
  }

  Future<bool> authenticate({String? reason}) async {
    try {
      final types = await availableBiometrics();
      final label = biometricLabel(types);
      return await _localAuth.authenticate(
        localizedReason:
            reason ?? 'Usá $label para entrar a Sportify Amateur',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}

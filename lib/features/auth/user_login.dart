import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';
import 'package:sportify_amateur/core/services/auth_storage_services.dart';
import 'package:sportify_amateur/core/services/biometric_auth_service.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isLoading = false;
  bool _obscure = true;
  bool _biometricAvailable = false;
  String _biometricLabel = 'biometría';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final bio = BiometricAuthService.instance;
    final userId = await AuthStorageService().getUserId();
    if (userId == null) return;
    if (!await bio.isEnabledForUser(userId)) return;
    if (!await bio.isDeviceSupported()) return;
    final types = await bio.availableBiometrics();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = true;
      _biometricLabel = bio.biometricLabel(types);
    });
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    try {
      final ok = await authService.tryBiometricUnlock();
      if (!ok) {
        throw Exception('No se pudo verificar $_biometricLabel');
      }
      if (context.mounted) {
        await authService.navigateAfterAuth(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.loginErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!response) {
        throw Exception('No se pudo iniciar sesión');
      }
      if (context.mounted) {
        await authService.navigateAfterAuth(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.loginErrorMessage(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: 0.85),
              primary.withValues(alpha: 0.45),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.35, 0.65],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sportify Amateur',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Iniciar sesión',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || !v.contains('@')) {
                                    return 'Ingresá un email válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 4) {
                                    return 'Ingresá tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _isLoading ? null : _login,
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              if (_biometricAvailable) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _loginWithBiometric,
                                  icon: const Icon(Icons.fingerprint),
                                  label: Text('Entrar con $_biometricLabel'),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: const Text('¿No tenés cuenta? Registrate'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

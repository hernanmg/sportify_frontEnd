import 'package:flutter/material.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<UserLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });
    try {
      final response = await authService.signInWithEmail(email, password);

      if (response) {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        throw Exception('Error en el login');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    // // Simulación de autenticación con el backend
    // await Future.delayed(const Duration(seconds: 2)); // Simular tiempo de red
    // if (email == 'adminexample.com' && password == 'password123') {
    //   const role = 'admin';
    //   await _storeTokenAndRole('fakeAdminToken', role);
    //   Navigator.pushReplacementNamed(context, '/dashboard');
    // } else if (email == 'user@example.com' && password == 'password123') {
    //   const role = 'user';
    //   await _storeTokenAndRole('fakeUserToken', role);
    //   Navigator.pushReplacementNamed(context, '/dashboard');
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Credenciales incorrectas')),
    //   );
    // }

    setState(() {
      _isLoading = false;
    });
  }

  // Future<void> _storeTokenAndRole(String token, String role) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('token', token);
  //   await prefs.setString('role', role);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}

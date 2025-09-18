import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenido a Sports Manager Pro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: FaIcon(
                FontAwesomeIcons.google,
                color: Colors.red,
              ),
              onPressed: () async {
                final success = await authService.signInWithGoogle();
                if (success && context.mounted) {
                  // Verificar si necesita onboarding
                  final authStatus = await authService.checkAuthStatus();
                  // Navigator.pushReplacementNamed(context, '/onboarding');
                  if (authStatus['needsOnboarding'] == true) {
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  } else {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                }
              },
              label: Text('Login with Google'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: FaIcon(
                FontAwesomeIcons.facebook,
                color: Color.fromARGB(255, 2, 39, 70),
              ),
              onPressed: () async {
                final success = await authService.signInWithFacebook();
                if (success && context.mounted) {
                  // Verificar si necesita onboarding
                  final authStatus = await authService.checkAuthStatus();
                  if (authStatus['needsOnboarding'] == true) {
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  } else {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                }
              },
              label: Text('Login with FaceBook'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              icon: FaIcon(
                FontAwesomeIcons.envelope,
                color: Color.fromARGB(255, 2, 39, 70),
              ),
              onPressed: () {
                // final success =
                //     await authService.signInWithEmail('pepa', 'password123');
                // if (success) {
                //   if (context.mounted) {
                //     // Flutter 3.7+ only
                //     Navigator.pushReplacementNamed(context, '/login');
                //   }
                // }
                Navigator.pushReplacementNamed(context, '/login');
              },
              label: Text('Login with E-mail'),
            ),
          ],
        ),
      ),
    );
  }
}

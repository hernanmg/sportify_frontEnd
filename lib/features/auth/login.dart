import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sportify_amateur/core/services/auth_services.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenido a Sportify Amateur')),
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
                if (success) {
                  if (context.mounted) {
                    // Flutter 3.7+ only
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
                if (success) {
                  if (context.mounted) {
                    // Flutter 3.7+ only
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
              onPressed: ()  {
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

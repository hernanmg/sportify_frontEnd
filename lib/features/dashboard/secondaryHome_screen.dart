import 'package:flutter/material.dart';

class SecondaryHomeScreen extends StatelessWidget {
  const SecondaryHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Usuarios'),
            onTap: () {
              Navigator.pushNamed(context, '/users');
            },
          ),
          ListTile(
            title: const Text('Roles'),
            onTap: () {
              Navigator.pushNamed(context, '/roles');
            },
          ),
        ],
      ),
    );
  }
}

// lib/admin_panel/configuracion.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
        child: const Text('Cerrar sesión'),
      ),
    );
  }
}

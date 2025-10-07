// lib/main_admin.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'admin_panel/login_admin.dart';
import 'admin_panel/embajadores_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _AdminApp());
}

class _AdminApp extends StatelessWidget {
  const _AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elite Army – Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      home: const _Gate(),
      routes: {
        // por si haces pushNamed desde el login
        '/adminHome': (_) => const AdminMain(),
      },
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({super.key});

  Future<bool> _isAdmin(User user) async {
    final idt = await user.getIdTokenResult(true);
    final token = idt.claims ?? {};
    if (token['admin'] == true) return true;

    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
    final role = (doc.data() ?? const {})['role']?.toString().toLowerCase() ?? '';
    return role == 'owner' || role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return LoginAdminScreen(); // ← sin const

        return FutureBuilder<bool>(
          future: _isAdmin(user),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (adminSnap.hasError || adminSnap.data != true) {
              FirebaseAuth.instance.signOut();
              return LoginAdminScreen(); // ← sin const
            }
            return const AdminMain();
          },
        );
      },
    );
  }
}

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      EmbajadoresAdminPage(), // sin const
      const _ConfigPage(),
    ];
    final titles = <String>['Embajadores', 'Configuración'];

    return Scaffold(
      appBar: AppBar(title: Text('PANEL DE ADMINISTRADOR · ${titles[_index]}')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Embajadores'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Config'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _ConfigPage extends StatelessWidget {
  const _ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PANEL DE ADMINISTRADOR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => LoginAdminScreen(), // ← sin const
                        ),
                        (r) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

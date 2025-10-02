// Elite Ambassadors – main.dart
// v0.3.1: Inicializa Firebase + tema oscuro unificado + AuthGate

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'core/locator.dart';
import 'core/theme.dart';
import 'login.dart';
import 'dashboard.dart';
import 'mi_red.dart';
import 'bonos_logros.dart';
import 'perfil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Locator.I.useMocks(); // por ahora datos mock
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elite Ambassadors',
      theme: AppTheme.dark(),
      home: const AuthGate(), // 👈 AuthGate decide login/tabs
      routes: {
        '/tabs': (_) => const _MainScaffold(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
        if (user == null) return const LoginPage();
        return const _MainScaffold();
      },
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold();
  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _index = 0;

  final _titles = const ['Dashboard', 'Mi Red', 'Bonos & Logros', 'Perfil'];
  final _pages = const [
    DashboardScreen(),
    MiRedScreen(),
    BonosLogrosScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.hub_outlined), label: 'Mi Red'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Bonos'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

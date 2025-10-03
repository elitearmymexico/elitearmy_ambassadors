// Elite Ambassadors – main.dart
// v0.3.3: Tabs + "Ver mi red" cambia de pestaña (sin push)

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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Locator.I.useFirebase();
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
      home: const AuthGate(),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return const LoginPage();
        return const _MainScaffold();
      },
    );
  }
}

class _MainScaffold extends StatefulWidget {
  const _MainScaffold({super.key});

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _index = 0;

  final _titles = const ['Dashboard', 'Mi Red', 'Bonos & Logros', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    // Construimos la página actual aquí para poder pasar callbacks
    Widget currentPage;
    switch (_index) {
      case 0:
        currentPage = DashboardScreen(
          onGoToRed: () => setState(() => _index = 1), // 👈 cambia de pestaña
        );
        break;
      case 1:
        currentPage = const MiRedScreen();
        break;
      case 2:
        currentPage = const BonosLogrosScreen();
        break;
      default:
        currentPage = const PerfilScreen();
    }

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: currentPage,
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

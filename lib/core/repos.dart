// lib/core/repos.dart
// Versión mínima para que compile con la app actual (LIVE).
// Provee UserRepo + UserRepoAuth y define tipos que faltaban.

import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

/// Algunos tipos que el proyecto referenciaba en otros puntos.
/// (Aunque hoy no los usemos, los dejamos definidos para evitar errores.)
enum AffiliatesFilter { all, direct }

class PayoutMonth {
  final String yearMonth; // ej. "2025-10"
  final double total;
  const PayoutMonth({required this.yearMonth, required this.total});
}

/// Contrato del repositorio de usuario que usa la UI (perfil, etc.)
abstract class UserRepo {
  /// Usuario Firebase actual (o null si no logueado)
  User? get currentUser;

  /// Resumen usado por la pantalla de Perfil (solo cosmético)
  Future<UserSummary> getSummary();

  /// Estos 3 setters son cosméticos (los guardamos en memoria local)
  Future<void> updatePhotoUrl(String url);
  Future<void> updateNetworkName(String name);
  Future<void> updateNotifications(bool enabled);
}

/// Implementación LIVE (usa FirebaseAuth para el usuario actual).
/// Los campos de foto/red/notificaciones se guardan en memoria del proceso;
/// no persisten en Firestore aún (son solo UI).
class UserRepoAuth implements UserRepo {
  String? _photoUrl;
  String? _networkName;
  bool _notif = true;

  @override
  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  Future<UserSummary> getSummary() async {
    final u = currentUser;
    final email = u?.email ?? 'usuario';
    final nameFallback = email.split('@').first;
    // rank y code aquí son placeholders (la app ya usa Firestore para nombre/código)
    return UserSummary(
      name: nameFallback,
      rank: 'Cabo',
      code: '-',
      photoUrl: _photoUrl,
      networkName: _networkName,
      notificationsEnabled: _notif,
    );
    // Si luego quieres leer nombre/rango reales de Firestore,
    // ya lo estamos haciendo en Dashboard/Perfil con embajadorRepo.
  }

  @override
  Future<void> updatePhotoUrl(String url) async {
    _photoUrl = url;
  }

  @override
  Future<void> updateNetworkName(String name) async {
    _networkName = name;
  }

  @override
  Future<void> updateNotifications(bool enabled) async {
    _notif = enabled;
  }
}

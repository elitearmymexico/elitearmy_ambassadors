// lib/admin_panel/admin_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  // Asegúrate que tus Functions están en us-central1
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Refresca el token para traer los claims (admin:true) actualizados.
  Future<void> refreshClaims() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await u.getIdToken(true);
    }
  }

  /// Llama a la callable: adminCreateAmbassador
  /// Crea usuario en Auth y tarjeta en ambassadors_master (inactiva)
  Future<Map<String, dynamic>> createAmbassador({
    required String email,
    required String password,
    String? nombre,
    String? phone,
  }) async {
    await refreshClaims();
    try {
      final res =
          await _functions.httpsCallable('adminCreateAmbassador').call({
        'email': email,
        'password': password,
        if (nombre != null) 'nombre': nombre,
        if (phone != null) 'phone': phone,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      throw Exception('internal: $e');
    }
  }

  /// Llama a la callable: adminActivateAmbassador
  /// Activa tarjeta (crea usuario en Auth si no existía)
  Future<Map<String, dynamic>> activateAmbassador({
    required String email,
    String? nombre,
    String? phone,
  }) async {
    await refreshClaims();
    try {
      final res =
          await _functions.httpsCallable('adminActivateAmbassador').call({
        'email': email,
        if (nombre != null) 'nombre': nombre,
        if (phone != null) 'phone': phone,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      throw Exception('internal: $e');
    }
  }

  /// Llama a la callable: setAdmin
  /// Asigna/remueve el claim admin:true a un UID
  Future<void> setAdmin(String uid, {bool admin = true}) async {
    await refreshClaims();
    try {
      await _functions.httpsCallable('setAdmin').call({
        'uid': uid,
        'admin': admin,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception('${e.code}: ${e.message}');
    } catch (e) {
      throw Exception('internal: $e');
    }
  }
}

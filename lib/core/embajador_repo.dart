// lib/core/embajador_repo.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class EmbajadorRepo {
  EmbajadorRepo({
    FirebaseFirestore? fs,
    FirebaseAuth? auth,
  })  : _fs = fs ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;

  /// Stream de la ficha en ambassadors_master del usuario logueado.
  /// Lee por email, compatible con `code` o `codigo`.
  Stream<Map<String, dynamic>?> streamActual() {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      return Stream<Map<String, dynamic>?>.value(null);
    }

    return _fs
        .collection('ambassadors_master')
        .where('email', isEqualTo: email)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;

      final data = snap.docs.first.data();

      // 🔁 Normaliza: usa "code" como estándar, aunque la ficha tenga "codigo".
      if (data['code'] == null && data['codigo'] != null) {
        data['code'] = data['codigo'];
      }

      return data;
    }).handleError((e, st) {
      debugPrint('streamActual error: $e');
    });
  }

  /// Lectura puntual
  Future<Map<String, dynamic>?> getActualOnce() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) return null;

    try {
      final q = await _fs
          .collection('ambassadors_master')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return null;

      final data = q.docs.first.data();

      if (data['code'] == null && data['codigo'] != null) {
        data['code'] = data['codigo'];
      }

      return data;
    } catch (e) {
      debugPrint('getActualOnce error: $e');
      return null;
    }
  }

  /// Stream de referidos (si sigues usando /embajadores/{uid}/referidos)
  Stream<List<Map<String, dynamic>>> streamReferidos() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _fs
        .collection('embajadores')
        .doc(uid)
        .collection('referidos')
        .orderBy('alta', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList())
        .handleError((e, st) {
      debugPrint('streamReferidos error: $e');
    });
  }
}

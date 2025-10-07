// lib/core/embajador_repo.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmbajadorRepo {
  EmbajadorRepo({
    FirebaseFirestore? fs,
    FirebaseAuth? auth,
  })  : _fs = fs ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _fs;
  final FirebaseAuth _auth;

  /// Stream del documento del embajador del usuario logueado.
  /// Importante: el ID del documento en /embajadores/ es el UID de FirebaseAuth.
  Stream<Map<String, dynamic>?> streamActual() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _fs
        .collection('embajadores')
        .doc(uid)                 // 👈 AHORA ES doc(uid), NO where('uid'==...)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Lectura puntual (si alguna pantalla quiere usar Future en vez de Stream)
  Future<Map<String, dynamic>?> getActualOnce() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final d = await _fs.collection('embajadores').doc(uid).get();
    return d.data();
  }

  /// Stream de la subcolección de referidos del embajador logueado
  Stream<List<Map<String, dynamic>>> streamReferidos() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _fs
        .collection('embajadores')
        .doc(uid)
        .collection('referidos')
        .orderBy('alta', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => d.data()).toList());
  }
}

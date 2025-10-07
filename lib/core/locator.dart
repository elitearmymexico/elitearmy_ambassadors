// lib/core/locator.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'repos.dart';               // UserRepoAuth()
import 'embajador_repo.dart';
import 'referidos_repo.dart';
import 'models.dart';

// ==== REPO DE PAGOS ==== //
abstract class PagosRepo {
  Stream<List<Pago>> getPagos(String uid);
}

class FirebasePagosRepo implements PagosRepo {
  final FirebaseFirestore db;
  FirebasePagosRepo(this.db);

  @override
  Stream<List<Pago>> getPagos(String uid) {
    return db
        .collection('embajadores')
        .doc(uid)
        .collection('pagos')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Pago.fromFirestore(d.id, d.data()))
            .toList());
  }
}

class _MockPagosRepo implements PagosRepo {
  @override
  Stream<List<Pago>> getPagos(String uid) async* {
    yield const <Pago>[];
  }
}

/// Service locator MUY simple.
class Locator {
  Locator._();
  static final I = Locator._();

  // Repos que usamos en la app
  late UserRepo userRepo;
  late EmbajadorRepo embajadorRepo;
  late ReferidosRepo referidosRepo;
  late PagosRepo pagosRepo; // ⬅️ nuevo

  /// Inicializa todo en modo LIVE (Firebase/Firestore).
  void useFirebase() {
    userRepo = UserRepoAuth();       // tu repo real de auth/usuario
    embajadorRepo = EmbajadorRepo(); // Firestore: embajadores (por uid)
    referidosRepo = ReferidosRepo(); // Firestore: subcolección "referidos"
    pagosRepo = FirebasePagosRepo(FirebaseFirestore.instance); // ⬅️ nuevo

    if (kDebugMode) debugPrint('Locator -> useFirebase()');
  }

  /// (Opcional) Modo mock si alguna vez lo necesitas.
  void useMocks() {
    userRepo = UserRepoAuth();
    embajadorRepo = EmbajadorRepo();
    referidosRepo = ReferidosRepo();
    pagosRepo = _MockPagosRepo();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ReferidosRepo {
  final _db = FirebaseFirestore.instance;

  Stream<List<Referido>> getReferidos(String embajadorUid) {
    return _db
        .collection('embajadores')
        .doc(embajadorUid)
        .collection('referidos')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Referido.fromFirestore(d.id, d.data())).toList());
  }
}

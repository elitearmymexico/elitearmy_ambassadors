// lib/core/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ===== PERFIL / USUARIO =====
class UserSummary {
  final String name;
  final String rank;
  final String code;
  final String? photoUrl;
  final String? networkName;
  final bool notificationsEnabled;

  const UserSummary({
    required this.name,
    required this.rank,
    required this.code,
    this.photoUrl,
    this.networkName,
    this.notificationsEnabled = true,
  });
}

// ===== ESTADÍSTICAS RED =====
class NetworkStats {
  final int directs;
  final int networkSize;
  final double balance;

  const NetworkStats({
    required this.directs,
    required this.networkSize,
    required this.balance,
  });
}

// ===== BONOS / LOGROS =====
class BonusTier {
  final int volume;
  final double reward;
  const BonusTier({required this.volume, required this.reward});
}

class Achievement {
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.title,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class Payout {
  final String id;
  final double amount;
  final DateTime date;

  const Payout({required this.id, required this.amount, required this.date});
}

// ===== RED & REFERIDOS =====
class Affiliate {
  final String name;
  final bool active;
  final bool direct;
  final DateTime joinedAt;

  const Affiliate({
    required this.name,
    required this.active,
    required this.direct,
    required this.joinedAt,
  });
}

class Referido {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final bool activo;
  final DateTime alta;

  const Referido({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.activo,
    required this.alta,
  });

  factory Referido.fromFirestore(String id, Map<String, dynamic> d) {
    // ✅ FIX: usa 'fecha' (Timestamp en tu Firestore) y fallbacks
    final altaRaw = d['fecha'] ?? d['alta'] ?? d['fecha_alta'];
    DateTime parsed;

    if (altaRaw is Timestamp) {
      parsed = altaRaw.toDate();
    } else if (altaRaw is DateTime) {
      parsed = altaRaw;
    } else if (altaRaw is int) {
      // Detecta si viene en segundos o milisegundos
      parsed = altaRaw > 2000000000
          ? DateTime.fromMillisecondsSinceEpoch(altaRaw)
          : DateTime.fromMillisecondsSinceEpoch(altaRaw * 1000);
    } else if (altaRaw is String) {
      final iso = DateTime.tryParse(altaRaw);
      if (iso != null) {
        parsed = iso;
      } else {
        final asInt = int.tryParse(altaRaw);
        if (asInt != null) {
          parsed = asInt > 2000000000
              ? DateTime.fromMillisecondsSinceEpoch(asInt)
              : DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
        } else {
          parsed = DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
    } else {
      parsed = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Referido(
      id: id,
      nombre: (d['nombre'] ?? '') as String,
      correo: (d['correo'] ?? '') as String,
      telefono: (d['telefono'] ?? '') as String,
      activo: (d['activo'] ?? false) as bool,
      alta: parsed,
    );
  }
}

// ===== PAGOS =====
class Pago {
  final String id;
  final double monto;
  /// "pagado" | "pendiente" | "rechazado"
  final String estatus;
  final DateTime fecha;

  Pago({
    required this.id,
    required this.monto,
    required this.estatus,
    required this.fecha,
  });

  factory Pago.fromFirestore(String id, Map<String, dynamic> d) {
    final rawFecha = d['fecha'];
    DateTime parsed;
    if (rawFecha is Timestamp) {
      parsed = rawFecha.toDate();
    } else if (rawFecha is int) {
      parsed = DateTime.fromMillisecondsSinceEpoch(rawFecha);
    } else if (rawFecha is String) {
      parsed = DateTime.tryParse(rawFecha) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      parsed = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Pago(
      id: id,
      monto: (d['monto'] as num?)?.toDouble() ?? 0.0,
      estatus: (d['estatus'] ?? '').toString(),
      fecha: parsed,
    );
  }

  // === utilidades de formato sin 'intl' ===
  String get fechaCorta {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString();
    return '$d/$m/$y';
  }

  String get fechaConHora {
    int h = fecha.hour;
    final m = fecha.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    final hh = h.toString().padLeft(2, '0');
    return '${fechaCorta} $hh:$m $ampm';
  }
}

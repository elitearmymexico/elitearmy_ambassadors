// Elite Ambassadors – bonos_logros.dart
// v0.8.0: Totales, Bono único del mes, Logros con “te faltan N”,
//         y Bonos por racha (3/6/9 meses) usando historial_mensual.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <- para racha

import 'core/locator.dart';
import 'core/models.dart';

class BonosLogrosScreen extends StatelessWidget {
  const BonosLogrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();

    return StreamBuilder<List<Pago>>(
      stream: Locator.I.pagosRepo.getPagos(uid),
      builder: (context, pagosSnap) {
        final pagos = pagosSnap.data ?? const <Pago>[];
        final totalPagado = pagos
            .where((p) => p.estatus.toLowerCase() == 'pagado')
            .fold<double>(0.0, (a, p) => a + p.monto);
        final totalPendiente = pagos
            .where((p) => p.estatus.toLowerCase() == 'pendiente')
            .fold<double>(0.0, (a, p) => a + p.monto);

        return StreamBuilder<List<Referido>>(
          stream: Locator.I.referidosRepo.getReferidos(uid),
          builder: (context, refSnap) {
            final referidos = refSnap.data ?? const <Referido>[];

            // === Bonos únicos del mes ===
            final nuevosActivosMes = referidos.where((r) =>
                r.activo &&
                r.alta.year == now.year &&
                r.alta.month == now.month).length;

            final bonoMes = _bonoUnicoPorNuevosActivos(nuevosActivosMes);
            final proximoTier = _siguienteTier(nuevosActivosMes);

            // === Rango (para "Logros") ===
            final activos = referidos.where((r) => r.activo).length;
            final rangoInfo = _calcularRangoConFaltantes(activos);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5D35FF), Color(0xFF7B1FA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Text(
                      'Bonos · Logros · Pagos',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Totales pagos
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _KpiBox(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Total pagado',
                        value: _fmt(totalPagado),
                      ),
                      _KpiBox(
                        icon: Icons.schedule_outlined,
                        label: 'Pendiente',
                        value: _fmt(totalPendiente),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bono único del mes
                  _SectionTitle('Bonos únicos del mes'),
                  const SizedBox(height: 8),
                  _BonusMesCard(
                    nuevosActivos: nuevosActivosMes,
                    bonoAlcanzado: bonoMes,
                    proximoTier: proximoTier,
                  ),

                  const SizedBox(height: 20),

                  // Historial de pagos
                  _SectionTitle('Historial de pagos'),
                  const SizedBox(height: 8),
                  ...pagos.map((p) => _PagoTile(p)).toList(),

                  const SizedBox(height: 24),

                  // Logros de rango (con “te faltan N…”)
                  _SectionTitle('Logros de rango'),
                  const SizedBox(height: 8),
                  _LogroRangoCard(info: rangoInfo),

                  const SizedBox(height: 24),

                  // Bonos por racha (3/6/9 meses) desde historial_mensual
                  _SectionTitle('Bonos por racha'),
                  const SizedBox(height: 8),
                  _RachaSection(uid: uid),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= Helpers de BONOS (mes) =================

  static const _tiers = <int, double>{
    3: 150,
    5: 400,
    10: 1000,
    20: 3000,
  };

  static double _bonoUnicoPorNuevosActivos(int nuevos) {
    double hit = 0;
    for (final e in _tiers.entries) {
      if (nuevos >= e.key) hit = e.value;
    }
    return hit;
  }

  static int? _siguienteTier(int nuevos) {
    final sorted = _tiers.keys.toList()..sort();
    for (final t in sorted) {
      if (nuevos < t) return t;
    }
    return null;
  }

  // ======= Rango con “faltantes” =======
  static _RangoInfo _calcularRangoConFaltantes(int activos) {
    if (activos >= 100) {
      return const _RangoInfo('Coronel', '—', 1.0, 0);
    } else if (activos >= 75) {
      return _progressBetween(
        activos,
        base: 75,
        next: 100,
        actual: 'Capitán',
        proximo: 'Coronel',
      );
    } else if (activos >= 50) {
      return _progressBetween(
        activos,
        base: 50,
        next: 75,
        actual: 'Teniente',
        proximo: 'Capitán',
      );
    } else if (activos >= 30) {
      return _progressBetween(
        activos,
        base: 30,
        next: 50,
        actual: 'Sargento',
        proximo: 'Teniente',
      );
    } else if (activos >= 15) {
      return _progressBetween(
        activos,
        base: 15,
        next: 30,
        actual: 'Cabo',
        proximo: 'Sargento',
      );
    } else {
      final p = (activos / 15.0).clamp(0, 1).toDouble();
      final faltan = (15 - activos).clamp(0, 15);
      return _RangoInfo('Recluta', 'Cabo', p, faltan);
    }
  }

  static _RangoInfo _progressBetween(
    int v, {
    required int base,
    required int next,
    required String actual,
    required String proximo,
  }) {
    final span = (next - base).toDouble();
    final p = ((v - base) / span).clamp(0, 1).toDouble();
    final faltan = (next - v).clamp(0, next - base);
    return _RangoInfo(actual, proximo, p, faltan);
  }

  static String _fmt(double n) => '\$${n.toStringAsFixed(2)}';
}

// ====================== Widgets ======================

class _KpiBox extends StatelessWidget {
  const _KpiBox({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const Spacer(),
          Text(label, style: text.labelLarge!.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: text.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.t, {super.key});
  final String t;
  @override
  Widget build(BuildContext context) {
    return Text(t, style: const TextStyle(fontWeight: FontWeight.w700));
  }
}

class _BonusMesCard extends StatelessWidget {
  const _BonusMesCard({
    required this.nuevosActivos,
    required this.bonoAlcanzado,
    required this.proximoTier,
  });
  final int nuevosActivos;
  final double bonoAlcanzado;
  final int? proximoTier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final tieneBono = bonoAlcanzado > 0;
    final titulo = tieneBono ? '¡Bono del mes desbloqueado!' : 'Aún sin bono del mes';
    final subtitulo = tieneBono
        ? 'Nuevos activos del mes: $nuevosActivos · Bono: \$${bonoAlcanzado.toStringAsFixed(0)}'
        : 'Nuevos activos del mes: $nuevosActivos';

    double progreso = 0;
    String hint = '—';
    if (proximoTier != null) {
      progreso = (nuevosActivos / proximoTier!).clamp(0, 1).toDouble();
      final faltan = (proximoTier! - nuevosActivos).clamp(0, proximoTier!);
      final mapa = {3: 150, 5: 400, 10: 1000, 20: 3000};
      final premio = mapa[proximoTier] ?? 0;
      hint = 'Te faltan $faltan para ganar un bono extra de \$${premio.toStringAsFixed(0)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitulo, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: proximoTier == null ? 1 : progreso,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PagoTile extends StatelessWidget {
  const _PagoTile(this.p, {super.key});
  final Pago p;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = p.estatus.toLowerCase();
    Color chipBg;
    String chipTxt;
    switch (status) {
      case 'pagado':
        chipBg = Colors.green;
        chipTxt = 'PAGADO';
        break;
      case 'pendiente':
        chipBg = Colors.orange;
        chipTxt = 'PENDIENTE';
        break;
      default:
        chipBg = Colors.red;
        chipTxt = 'RECHAZADO';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\$${p.monto.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(p.fecha.toLocal().toString().split(' ').first,
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(chipTxt,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          )
        ],
      ),
    );
  }
}

class _LogroRangoCard extends StatelessWidget {
  const _LogroRangoCard({required this.info, super.key});
  final _RangoInfo info;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hint = info.faltan == 0 ? 'Rango máximo alcanzado' : 'Te faltan ${info.faltan} para ${info.proximoRango}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Chip(
              label: Text(info.rangoActual,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.indigo,
            ),
            const SizedBox(width: 8),
            Text('Próximo: ${info.proximoRango}'),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ============ Bonos por racha (historial_mensual) ============

class _RachaSection extends StatelessWidget {
  const _RachaSection({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('embajadores')
        .doc(uid)
        .collection('historial_mensual'); // docs: 'YYYY-MM', campo: activos:int

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? const [];

        if (docs.isEmpty) {
          return _InfoCard(
            title: 'Sin historial aún',
            body:
                'Para activar los bonos de racha, guarda por mes un documento '
                'en "historial_mensual" con id "YYYY-MM" y campo numérico "activos".',
          );
        }

        // Parseamos a lista (yyyyMM, activos)
        final meses = docs.map((d) {
          final id = d.id; // '2025-10'
          final parts = id.split('-');
          int ym = 0;
          if (parts.length == 2) {
            final y = int.tryParse(parts[0]) ?? 0;
            final m = int.tryParse(parts[1]) ?? 0;
            ym = y * 100 + m;
          }
          final act = (d.data()['activos'] as num?)?.toInt() ?? 0;
          return _MesActivos(ym: ym, activos: act);
        }).toList()
          ..sort((a, b) => a.ym.compareTo(b.ym)); // ascendente

        // Streak actual contando hacia atrás desde el mes más reciente.
        final s10 = _streak(meses, 10);
        final s20 = _streak(meses, 20);

        final card10 = _RachaCard(
          titulo: 'Racha con ≥10 activos',
          streak: s10,
          umbral: 10,
          premios: const {3: 300, 6: 600, 9: 900},
        );

        final card20 = _RachaCard(
          titulo: 'Racha con ≥20 activos',
          streak: s20,
          umbral: 20,
          premios: const {3: 600, 6: 1200, 9: 1800},
        );

        return Column(children: [card10, const SizedBox(height: 12), card20]);
      },
    );
  }

  // Cuenta meses consecutivos al final (más recientes) con activos >= umbral.
  static int _streak(List<_MesActivos> meses, int umbral) {
    if (meses.isEmpty) return 0;
    int c = 0;
    for (int i = meses.length - 1; i >= 0; i--) {
      if (meses[i].activos >= umbral) {
        c++;
      } else {
        break;
      }
    }
    return c;
  }
}

class _RachaCard extends StatelessWidget {
  const _RachaCard({
    required this.titulo,
    required this.streak,
    required this.umbral,
    required this.premios,
  });

  final String titulo;
  final int streak;
  final int umbral;
  final Map<int, int> premios; // meses -> monto

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Premio alcanzado y próximo hito
    int premioHit = 0;
    int? proximo;
    final hits = premios.keys.toList()..sort();
    for (final h in hits) {
      if (streak >= h) premioHit = premios[h]!;
      if (streak < h && proximo == null) proximo = h;
    }

    final tituloCard = premioHit > 0
        ? '¡Racha activa: $streak meses!'
        : 'Racha actual: $streak meses';

    String hint;
    double progreso;
    if (proximo == null) {
      hint = premioHit > 0 ? 'Máximo hito conseguido (${hits.last} meses)' : 'Aún sin hito alcanzado';
      progreso = 1;
    } else {
      final faltan = (proximo! - streak).clamp(0, proximo!);
      hint = 'Te faltan $faltan meses para \$${premios[proximo]!.toStringAsFixed(0)}';
      progreso = (streak / proximo!).clamp(0, 1).toDouble();
    }

    final subtitulo = 'Umbral: ≥$umbral activos';
    final premioTxt = premioHit > 0 ? 'Premio actual: \$${premioHit.toStringAsFixed(0)}' : 'Premio actual: —';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitulo, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(premioTxt, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progreso, minHeight: 6),
          ),
          const SizedBox(height: 6),
          Text(hint, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ====== structs auxiliares ======
class _MesActivos {
  final int ym; // YYYYMM
  final int activos;
  const _MesActivos({required this.ym, required this.activos});
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body, super.key});
  final String title, body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// Struct de rango (con faltantes)
class _RangoInfo {
  final String rangoActual;
  final String proximoRango;
  final double progress;
  final int faltan;
  const _RangoInfo(this.rangoActual, this.proximoRango, this.progress, this.faltan);
}

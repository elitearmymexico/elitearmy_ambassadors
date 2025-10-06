// Elite Ambassadors – mi_red.dart
// KPIs alineados como Dashboard + listado de referidos

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/locator.dart';
import 'core/models.dart';
import 'widgets/kpis.dart';
import 'utils/dates.dart'; // ✅ nuevo import para manejar las fechas correctamente

class MiRedScreen extends StatelessWidget {
  const MiRedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cs  = Theme.of(context).colorScheme;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: Locator.I.embajadorRepo.streamActual(),
      builder: (context, embSnap) {
        if (embSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final e = embSnap.data;

        if (e == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_off, size: 48),
                  const SizedBox(height: 12),
                  const Text('Aún no tienes ficha de embajador.', textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    'Pídele al admin que te dé de alta en Firestore → colección "embajadores".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        final nombre = (e['nombre'] ?? '').toString();
        final foto   = (e['foto'] ?? '').toString();
        final activo = (e['boton'] ?? e['activo'] ?? false) == true;

        return StreamBuilder<List<Referido>>(
          stream: Locator.I.referidosRepo.getReferidos(uid),
          builder: (context, rSnap) {
            final referidos    = rSnap.data ?? const <Referido>[];
            final redTotal     = referidos.length;
            final activosEnRed = referidos.where((r) => r.activo).length;
            final gananciasMes = activosEnRed * 100.0;

            final rangoInfo     = _calcularRango(activosEnRed);
            final rangoActual   = rangoInfo.rangoActual;
            final proximoRango  = rangoInfo.proximoRango;
            final progreso      = rangoInfo.progress;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con avatar + rango (igual que Dashboard)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFF880E4F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (foto.isNotEmpty) ? NetworkImage(foto) : null,
                          child: (foto.isEmpty) ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre.isEmpty ? 'Embajador' : nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text('Rango actual: $rangoActual  ·  Próximo: $proximoRango',
                                  style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progreso.clamp(0, 1).toDouble(),
                                  minHeight: 6,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          label: Text(
                            activo ? 'ACTIVO' : 'INACTIVO',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          backgroundColor: activo ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // KPIs (usa los nombres correctos)
                  KpiGrid(
                    redTotal: redTotal,
                    activos: activosEnRed,
                    ganancias: gananciasMes,
                  ),

                  const SizedBox(height: 18),
                  Text('Tus referidos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),

                  ...referidos.map((r) => _ReferidoTile(r)).toList(),
                  if (referidos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text('Aún no tienes referidos.', style: TextStyle(color: cs.onSurfaceVariant)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== Rangos por #activos (igual que Dashboard)
  static _RangoInfo _calcularRango(int activos) {
    if (activos >= 100) {
      return const _RangoInfo('Coronel', '—', 1.0);
    } else if (activos >= 75) {
      return _progressBetween(activos, base: 75, next: 100, actual: 'Capitán',  proximo: 'Coronel');
    } else if (activos >= 50) {
      return _progressBetween(activos, base: 50, next: 75, actual: 'Teniente', proximo: 'Capitán');
    } else if (activos >= 30) {
      return _progressBetween(activos, base: 30, next: 50, actual: 'Sargento', proximo: 'Teniente');
    } else if (activos >= 15) {
      return _progressBetween(activos, base: 15, next: 30, actual: 'Cabo',     proximo: 'Sargento');
    } else {
      final progress = activos / 15.0;
      return _RangoInfo('Recluta', 'Cabo', progress);
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
    return _RangoInfo(actual, proximo, p);
  }
}

class _RangoInfo {
  final String rangoActual;
  final String proximoRango;
  final double progress;
  const _RangoInfo(this.rangoActual, this.proximoRango, this.progress);
}

// ===== UI helpers =====

class _ReferidoTile extends StatelessWidget {
  const _ReferidoTile(this.r, {super.key});
  final Referido r;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            child: Text(r.nombre.isNotEmpty ? r.nombre[0].toUpperCase() : 'R'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(r.correo, style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                // ✅ FIX: se corrige la fecha 1969
                Text(
                  'Alta: ${fechaLarga(_altaSegura(r.alta))}',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(r.activo ? 'ACTIVO' : 'INACTIVO',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            backgroundColor: r.activo ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  // ✅ Helper local para corregir fechas inválidas
  DateTime _altaSegura(dynamic v) {
    final d = toDateSafe(v);
    if (d.year < 1971) {
      final ms = d.millisecondsSinceEpoch;
      if (ms > 0 && ms < 2000000000) {
        return DateTime.fromMillisecondsSinceEpoch(ms * 1000);
      }
    }
    return d;
  }
}

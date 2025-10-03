// lib/mi_red.dart
// v0.6.0: Header igual al Dashboard, KPIs reales y lista de referidos (sin AppBar)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/locator.dart';
import 'core/models.dart'; // Referido

class MiRedScreen extends StatelessWidget {
  const MiRedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      // 👇 Sin AppBar: usamos el header visual
      body: StreamBuilder<Map<String, dynamic>?>(
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
                    const Icon(Icons.person_search, size: 48),
                    const SizedBox(height: 12),
                    const Text('Aún no tienes ficha de embajador.'),
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
              if (rSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (rSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42),
                        const SizedBox(height: 8),
                        const Text('No se pudo cargar tu red'),
                        const SizedBox(height: 6),
                        Text(
                          '${rSnap.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final referidos = rSnap.data ?? const <Referido>[];
              final redTotal  = referidos.length;
              final activos   = referidos.where((r) => r.activo).length;
              final ganancias = activos * 100.0;

              final rango = _calcularRango(activos);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Header igual al Dashboard =====
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
                            backgroundImage:
                                foto.isNotEmpty ? NetworkImage(foto) : null,
                            child: foto.isEmpty ? const Icon(Icons.person) : null,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rango actual: ${rango.rangoActual}  ·  Próximo: ${rango.proximoRango}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: rango.progress.clamp(0.0, 1.0),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: activo ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== KPIs =====
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.35,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _StatCard(label: 'Red total',     value: '$redTotal',                         icon: Icons.hub),
                        _StatCard(label: 'Activos en red', value: '$activos',                          icon: Icons.bolt),
                        _StatCard(label: 'Ganancias mes',  value: '\$${ganancias.toStringAsFixed(2)}', icon: Icons.payments),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ===== Lista de referidos =====
                    if (referidos.isEmpty)
                      _EmptyState(
                        title: 'Aún no tienes referidos',
                        subtitle:
                            'Comparte tu enlace desde el Dashboard para invitar a tus primeros directos.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: referidos.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, thickness: .5),
                        itemBuilder: (context, i) {
                          final a = referidos[i];
                          final fecha =
                              '${a.alta.day.toString().padLeft(2, '0')}/'
                              '${a.alta.month.toString().padLeft(2, '0')}/'
                              '${a.alta.year}';
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                a.nombre.isNotEmpty
                                    ? a.nombre[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(a.nombre,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              'Alta: $fecha · ${a.correo}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: _estadoBadge(a.activo),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* ================= Helpers UI/logic ================= */

Widget _estadoBadge(bool activo) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: activo ? const Color(0xFF1E7F37) : const Color(0xFF912626),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      activo ? 'ACTIVO' : 'INACTIVO',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.group_add_outlined, size: 56, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const Spacer(),
          Text(label, style: text.labelLarge!.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: text.headlineMedium!.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/* ===== Rango automático según # de activos =====
   Recluta: 0–14
   Cabo:    15–29
   Sargento:30–49
   Teniente:50–74
   Capitán: 75–99
   Coronel: 100+
*/
class _RangoInfo {
  final String rangoActual;
  final String proximoRango;
  final double progress; // 0..1 hacia el próximo rango
  const _RangoInfo(this.rangoActual, this.proximoRango, this.progress);
}

_RangoInfo _calcularRango(int activos) {
  if (activos >= 100) {
    return const _RangoInfo('Coronel', '—', 1.0);
  } else if (activos >= 75) {
    return _progressBetween(activos, base: 75, next: 100, actual: 'Capitán', proximo: 'Coronel');
  } else if (activos >= 50) {
    return _progressBetween(activos, base: 50, next: 75, actual: 'Teniente', proximo: 'Capitán');
  } else if (activos >= 30) {
    return _progressBetween(activos, base: 30, next: 50, actual: 'Sargento', proximo: 'Teniente');
  } else if (activos >= 15) {
    return _progressBetween(activos, base: 15, next: 30, actual: 'Cabo', proximo: 'Sargento');
  } else {
    final p = activos / 15.0; // Recluta → Cabo
    return _RangoInfo('Recluta', 'Cabo', p);
  }
}

_RangoInfo _progressBetween(
  int v, {
  required int base,
  required int next,
  required String actual,
  required String proximo,
}) {
  final span = (next - base).toDouble();
  final p = ((v - base) / span).clamp(0.0, 1.0);
  return _RangoInfo(actual, proximo, p);
}

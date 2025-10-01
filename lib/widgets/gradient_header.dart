// lib/widgets/gradient_header.dart
import 'package:flutter/material.dart';
import '../core/locator.dart';
import '../core/models.dart';

/// Header reutilizable con degradado rojo→negro
/// Muestra: nombre, rango actual, próximo rango y barra de progreso.
/// No requiere parámetros.
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key, this.showSettings = false});

  /// Si lo deseas, puedes mostrar un botón (engranaje) a la derecha.
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<UserSummary>(
      future: Locator.I.userRepo.getSummary(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Skeleton();
        }
        if (!snap.hasData) return const _Skeleton();

        final u = snap.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB71C1C), Colors.black],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texto principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Rango actual: ${u.rank}  ·  Próximo: ${u.nextRank}',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: u.progress.clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(u.progress * 100).toStringAsFixed(0)}% completado',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              if (showSettings)
                Container(
                  margin: const EdgeInsets.only(left: 12, top: 4),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    tooltip: 'Opciones',
                    onPressed: () {},
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    // Placeholder mientras carga
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D1B1B), Colors.black87],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 140, color: Colors.white24),
          const SizedBox(height: 10),
          Container(height: 12, width: 220, color: Colors.white24),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: null,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 10, width: 100, color: Colors.white24),
        ],
      ),
    );
  }
}

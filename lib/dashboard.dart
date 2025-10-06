// Elite Ambassadors – dashboard.dart
// v0.5.2: Rangos automáticos + KPIs + botón "Ver mi red" cambia de pestaña

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/locator.dart';
import 'core/models.dart';
import 'mi_red.dart';
import 'widgets/kpis.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onGoToRed});

  /// Si viene este callback, lo usamos para cambiar de pestaña.
  /// Si es null, hacemos un Navigator.push como fallback.
  final VoidCallback? onGoToRed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
                  const Icon(Icons.person_search, size: 48),
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
        final codigo = (e['codigo'] ?? '').toString();
        final activo = (e['boton'] ?? e['activo'] ?? false) == true;

        final inviteUrl = 'https://elite-army-mexico.crosshero.site/?ref=$codigo';

        return StreamBuilder<List<Referido>>(
          stream: Locator.I.referidosRepo.getReferidos(uid),
          builder: (context, rSnap) {
            final referidos = rSnap.data ?? const <Referido>[];
            final redTotal  = referidos.length;
            final activos   = referidos.where((r) => r.activo).length;
            final ganancias = activos * 100.0;

            final rangoInfo     = _calcularRango(activos);
            final rangoActual   = rangoInfo.rangoActual;
            final proximoRango  = rangoInfo.proximoRango;
            final progreso      = rangoInfo.progress;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con avatar + rango
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

                  // KPIs (reemplaza tu GridView actual por esto)
                KpiGrid(
                        redTotal: redTotal,
                        activos: activos,
                        ganancias: ganancias,
                        ),

                  const SizedBox(height: 12),

                  // "Ver mi red" -> cambia de pestaña si hay callback
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (onGoToRed != null) {
                          onGoToRed!(); // ✅ cambia a la pestaña "Mi Red"
                        } else {
                          // Fallback si alguien usa DashboardScreen suelto
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MiRedScreen()));
                        }
                      },
                      icon: const Icon(Icons.people_alt_outlined),
                      label: const Text('Ver mi red'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _CodigoCard(
                    codigo: codigo.isEmpty ? '—' : codigo,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: codigo));
                      _toast(context, 'Código copiado');
                    },
                  ),
                  const SizedBox(height: 12),

                  _EnlaceCard(
                    enlace: inviteUrl,
                    onShare: () => _abrirWhatsappConTexto(
                      context,
                      '¡Hola! Te comparto mi enlace de registro a Elite Army: $inviteUrl',
                    ),
                  ),
                  const SizedBox(height: 12),

                  _ReingresosCard(
                    onSend: (nombreCliente) {
                      final n = nombreCliente.trim();
                      if (n.isEmpty) {
                        _toast(context, 'Escribe el nombre primero');
                        return;
                      }
                      final msg = 'Reingreso: Favor de reactivar a *$n* y asignarlo a mi red. Código: $codigo';
                      _abrirWhatsappConTexto(context, msg);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== Helpers =====

  static Future<void> _abrirWhatsappConTexto(BuildContext context, String texto) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        _toast(context, 'No se pudo abrir WhatsApp. Enlace copiado.');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      _toast(context, 'No se pudo abrir WhatsApp. Enlace copiado.');
    }
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ===== Rangos por #activos =====
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

class _CodigoCard extends StatelessWidget {
  const _CodigoCard({required this.codigo, required this.onCopy});
  final String codigo;
  final VoidCallback onCopy;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu código de invitación', style: text.titleSmall),
                const SizedBox(height: 6),
                Text(codigo, style: text.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(onPressed: onCopy, tooltip: 'Copiar', icon: const Icon(Icons.copy)),
        ],
      ),
    );
  }
}

class _EnlaceCard extends StatelessWidget {
  const _EnlaceCard({required this.enlace, required this.onShare});
  final String enlace;
  final VoidCallback onShare;

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
          Text('Tu enlace de invitación', style: text.titleSmall),
          const SizedBox(height: 6),
          SelectableText(enlace, style: TextStyle(color: cs.primary)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
        ],
      ),
    );
  }
}

class _ReingresosCard extends StatefulWidget {
  const _ReingresosCard({required this.onSend, super.key});
  final void Function(String nombreCliente) onSend;

  @override
  State<_ReingresosCard> createState() => _ReingresosCardState();
}

class _ReingresosCardState extends State<_ReingresosCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
          const Text('Reingresos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Escribe el nombre del cliente a reactivar y envía el mensaje a recepción por WhatsApp.'),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Nombre del cliente a reactivar',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(onPressed: () => widget.onSend(_ctrl.text), child: const Text('Enviar por WhatsApp')),
              const SizedBox(width: 12),
              TextButton(onPressed: () => _ctrl.clear(), child: const Text('Limpiar')),
            ],
          ),
        ],
      ),
    );
  }
}

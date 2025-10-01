// Elite Ambassadors – dashboard.dart
// Version: v0.2.1
// - v0.2.1: Header unificado (GradientHeader rojo→negro) + KPIs, código, enlace y reingresos.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/locator.dart';
import 'core/models.dart';
import 'widgets/gradient_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<UserSummary> _future;
  final _reingresoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = Locator.I.userRepo.getSummary();
  }

  @override
  void dispose() {
    _reingresoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<UserSummary>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) return const Center(child: Text('Sin datos'));

        final u = snap.data!;
        final inviteUrl = Locator.I.referralsRepo.buildInviteUrl(u.code);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === Header unificado rojo→negro ===
              const GradientHeader(),
              const SizedBox(height: 24), // <-- ESPACIO BAJO EL HEADER

              // KPIs rápidos
              _StatsGrid(
                directos: u.directs,
                redTotal: u.network,
                activosMes: u.activeThisMonth,
              ),
              const SizedBox(height: 28),

              // Código + copiar
              _CodigoCard(
                codigo: u.code,
                onCopy: () async {
                  await Clipboard.setData(ClipboardData(text: u.code));
                  _toast('Código copiado');
                },
              ),
              const SizedBox(height: 12),

              // Enlace + WhatsApp
              _EnlaceCard(
                enlace: inviteUrl,
                onShare: () => _abrirWhatsappConTexto(
                  '¡Hola! Te comparto mi enlace de registro a Elite Army: $inviteUrl',
                ),
              ),
              const SizedBox(height: 12),

              // Reingresos
              _ReingresosCard(
                controller: _reingresoCtrl,
                onSend: () {
                  final nombre = _reingresoCtrl.text.trim();
                  if (nombre.isEmpty) return _toast('Escribe el nombre primero');
                  final msg =
                      'Reingreso: Favor de reactivar a *$nombre* y asignarlo a mi red. Código: ${u.code}';
                  _abrirWhatsappConTexto(msg);
                },
                onClear: () => _reingresoCtrl.clear(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirWhatsappConTexto(String texto) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        _toast('No se pudo abrir WhatsApp. Enlace copiado.');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      _toast('No se pudo abrir WhatsApp. Enlace copiado.');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ================== UI helpers ==================

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.directos,
    required this.redTotal,
    required this.activosMes,
  });
  final int directos, redTotal, activosMes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _StatCard(label: 'Directos', value: '$directos', icon: Icons.group_add),
        _StatCard(label: 'Red total', value: '$redTotal', icon: Icons.hub),
        _StatCard(label: 'Activos mes', value: '$activosMes', icon: Icons.bolt),
      ],
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
          Text(
            label,
            style: text.labelLarge!.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: text.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
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
                Text(
                  codigo,
                  style: text.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
                ),
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

class _ReingresosCard extends StatelessWidget {
  const _ReingresosCard({
    required this.controller,
    required this.onSend,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onSend, onClear;

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
          const Text(
            'Escribe el nombre del cliente a reactivar y envía el mensaje a recepción por WhatsApp.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
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
              FilledButton(onPressed: onSend, child: const Text('Enviar por WhatsApp')),
              const SizedBox(width: 12),
              TextButton(onPressed: onClear, child: const Text('Limpiar')),
            ],
          ),
        ],
      ),
    );
  }
}

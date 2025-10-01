// lib/mi_red.dart
import 'package:flutter/material.dart';
import 'core/locator.dart';
import 'core/models.dart';
import 'widgets/gradient_header.dart';
import 'widgets/historial_pagos.dart';


// Helper para icono por rango
IconData rankIconFor(String rank) {
  final r = rank.toLowerCase();
  if (r.contains('general')) return Icons.shield;
  if (r.contains('coronel')) return Icons.military_tech;
  if (r.contains('capit')) return Icons.workspace_premium;
  if (r.contains('tenien')) return Icons.workspace_premium_outlined;
  if (r.contains('sargen')) return Icons.grade;
  if (r.contains('cabo')) return Icons.verified;
  return Icons.emoji_events_outlined;
}

class MiRedScreen extends StatefulWidget {
  const MiRedScreen({super.key});
  @override
  State<MiRedScreen> createState() => _MiRedScreenState();
}

class _MiRedScreenState extends State<MiRedScreen> {
  late Future<NetworkStats> _statsF;
  late Future<List<Affiliate>> _affF;

  @override
  void initState() {
    super.initState();
    _statsF = Locator.I.networkRepo.getStats();
    _affF = Locator.I.networkRepo.getAffiliates(filter: AffiliatesFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(),
          const SizedBox(height: 16),

          // KPI cards
          FutureBuilder<NetworkStats>(
            future: _statsF,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final s = snap.data ??
                  const NetworkStats(directs: 0, networkSize: 0, balance: 0);
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _kpiCard(context, 'Directos', '${s.directs}',
                      Icons.group_add, onTap: () {
                    _openList(context, AffiliatesFilter.direct);
                  }),
                  _kpiCard(context, 'Red total', '${s.networkSize}',
                      Icons.hub, onTap: () {
                    _openList(context, AffiliatesFilter.all);
                  }),
                  _kpiCard(
                    context,
                    'Balance red',
                    '\$${s.balance.toStringAsFixed(2)}',
                    Icons.credit_card,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          // Botón para ver lista (todos)
          FilledButton.icon(
            onPressed: () => _openList(context, AffiliatesFilter.all),
            icon: const Icon(Icons.people_alt),
            label: const Text('Ver afiliados'),
          ),

          const SizedBox(height: 24),
          // Historial de pagos (tu widget nuevo)
        const SizedBox(height: 16),
HistorialPagos(), // <-- sin 'const',
        ],
      ),
    );
  }

  Widget _kpiCard(BuildContext ctx, String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    final cs = Theme.of(ctx).colorScheme;
    final text = Theme.of(ctx).textTheme;
    final card = Container(
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
          Text(label,
              style: text.labelLarge!.copyWith(color: cs.onSurfaceVariant)),
          Text(value,
              style: text.headlineMedium!
                  .copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(14), child: card);
  }

  void _openList(BuildContext ctx, AffiliatesFilter f) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => AffiliadosListScreen(filter: f),
    ));
  }
}

class AffiliadosListScreen extends StatelessWidget {
  const AffiliadosListScreen({super.key, required this.filter});
  final AffiliatesFilter filter;

  @override
  Widget build(BuildContext context) {
    final repo = Locator.I.networkRepo;
    return Scaffold(
      appBar: AppBar(title: const Text('Afiliados')),
      body: FutureBuilder<List<Affiliate>>(
        future: repo.getAffiliates(filter: filter),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data ?? const <Affiliate>[];
          if (data.isEmpty) {
            return const Center(child: Text('Sin afiliados'));
          }
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, thickness: 0.5),
            itemBuilder: (context, i) {
              final a = data[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(a.name.isNotEmpty ? a.name[0] : '?'),
                ),
                title:
                    Text(a.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  'Alta: ${a.joinedAt.day}/${a.joinedAt.month}/${a.joinedAt.year}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: a.active
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('ACTIVO',
                            style: TextStyle(color: Colors.white)),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

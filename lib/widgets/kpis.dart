// Elite Ambassadors – widgets/kpis.dart
// KPIs reutilizables (Dashboard, Mi Red)

import 'package:flutter/material.dart';

class KpiGrid extends StatelessWidget {
  const KpiGrid({
    super.key,
    required this.redTotal,
    required this.activos,
    required this.ganancias,
  });

  final int redTotal;
  final int activos;
  final double ganancias;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _KpiCard(
          icon: Icons.share,
          label: 'Red total',
          value: redTotal.toString(),
          color: cs.primaryContainer,
        ),
        _KpiCard(
          icon: Icons.bolt,
          label: 'Activos\nen red', // salto manual opcional
          value: activos.toString(),
          color: cs.secondaryContainer,
        ),
        _KpiCard(
          icon: Icons.monetization_on,
          label: 'Ganancias\nmes', // salto manual opcional
          value: '\$${ganancias.toStringAsFixed(2)}',
          color: cs.tertiaryContainer,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: text.headlineSmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium!.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

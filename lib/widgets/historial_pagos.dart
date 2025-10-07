import 'package:flutter/material.dart';
import '../../core/locator.dart';
import '../../core/models.dart';

class HistorialPagos extends StatelessWidget {
  const HistorialPagos({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PayoutMonth>(
      future: Locator.I.payoutsRepo.getByMonth(_currentMonthKey()),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final pm = snap.data;
        if (pm == null || pm.items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Historial de pagos (mes actual)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...pm.items.map((it) => _payoutTile(context, it)),
          ],
        );
      },
    );
  }

  String _currentMonthKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    return '${now.year}-$mm';
  }

  Widget _payoutTile(BuildContext context, PayoutItem it) {
    final cs = Theme.of(context).colorScheme;
    IconData icon;
    switch (it.type) {
      case 'direct': icon = Icons.person_add; break;
      case 'bonus': icon = Icons.star; break;
      case 'payment': icon = Icons.account_balance_wallet; break;
      default: icon = Icons.receipt_long;
    }
    Color badgeColor;
    String badgeText;
    switch (it.status) {
      case 'confirmed': badgeColor = Colors.teal; badgeText = 'CONFIRMED'; break;
      case 'pending':   badgeColor = Colors.orange; badgeText = 'PENDING'; break;
      case 'paid':      badgeColor = Colors.green; badgeText = 'PAID'; break;
      default:          badgeColor = cs.outline; badgeText = it.status.toUpperCase();
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text('${it.type.toUpperCase()} · \$${it.amount.toStringAsFixed(2)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (it.source != null) Text(it.source!, style: const TextStyle(color: Colors.white70)),
            Text('${it.date.year}-${it.date.month.toString().padLeft(2,'0')}-${it.date.day.toString().padLeft(2,'0')}',
                style: const TextStyle(color: Colors.white60)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(badgeText, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

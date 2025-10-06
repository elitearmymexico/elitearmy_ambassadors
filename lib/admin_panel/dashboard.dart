import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance.collection('ambassadors_master');
    final activos = col.where('activo', isEqualTo: true).snapshots();
    final todos = col.snapshots();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Align(alignment: Alignment.centerLeft, child: Text('Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          Row(
            children: [
              _Kpi(title: 'Embajadores activos', stream: activos, value: (s) => s.size),
              const SizedBox(width: 12),
              _Kpi(title: 'Total embajadores', stream: todos, value: (s) => s.size),
            ],
          ),
          const Spacer(),
          const Text('Más KPIs vendrán aquí…'),
          const Spacer(),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.title, required this.stream, required this.value});
  final String title;
  final Stream<QuerySnapshot> stream;
  final int Function(QuerySnapshot) value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (_, snap) {
              final v = snap.hasData ? value(snap.data!) : 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 8),
                  Text('$v', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

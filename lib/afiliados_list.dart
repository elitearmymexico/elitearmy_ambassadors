// Elite Ambassadors – afiliados_list.dart (v1.0 simple)
// Lista de afiliados con filtro (all/direct/active) y manejo de errores.

import 'package:flutter/material.dart';
import 'core/locator.dart';
import 'core/models.dart';

class AfiliadosListScreen extends StatelessWidget {
  const AfiliadosListScreen({super.key, this.filter = AffiliatesFilter.all});
  final AffiliatesFilter filter;

  @override
  Widget build(BuildContext context) {
    final title = switch (filter) {
      AffiliatesFilter.all => 'Todos los afiliados',
      AffiliatesFilter.direct => 'Afiliados directos',
      AffiliatesFilter.active => 'Afiliados activos',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<Affiliate>>(
        future: Locator.I.networkRepo.getAffiliates(filter: filter),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar la lista.\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final list = snap.data ?? const <Affiliate>[];
          if (list.isEmpty) {
            return const Center(child: Text('Sin afiliados aún'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = list[i];
              final joined =
                  '${a.joinedAt.year}-${a.joinedAt.month.toString().padLeft(2, '0')}-${a.joinedAt.day.toString().padLeft(2, '0')}';
              return ListTile(
                leading: CircleAvatar(child: Text(a.name.isNotEmpty ? a.name[0] : '?')),
                title: Text(a.name),
                subtitle: Text('Se unió: $joined'),
                trailing: Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: a.active ? Colors.green.shade700 : Colors.grey.shade700,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    a.active ? 'ACTIVO' : 'INACTIVO',
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  ),
),
                    ? const Chip(
                        label: Text('ACTIVO'),
                        visualDensity: VisualDensity.compact,
                      )
                    : const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

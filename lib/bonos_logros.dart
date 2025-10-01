// lib/bonos_logros.dart
import 'package:flutter/material.dart';
import 'core/locator.dart';
import 'core/models.dart';
import 'widgets/gradient_header.dart';

class BonosLogrosScreen extends StatefulWidget {
  const BonosLogrosScreen({super.key});
  @override
  State<BonosLogrosScreen> createState() => _BonosLogrosScreenState();
}

class _BonosLogrosScreenState extends State<BonosLogrosScreen> {
  late Future<List<BonusTier>> _tiersF;
  late Future<List<Achievement>> _achsF;

  @override
  void initState() {
    super.initState();
    _tiersF = Locator.I.achievementsRepo.getBonusTiers();
    _achsF = Locator.I.achievementsRepo.getAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(), // header unificado
          const SizedBox(height: 16),

          const Text('Bonos mensuales por volumen',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FutureBuilder<List<BonusTier>>(
            future: _tiersF,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final tiers = snap.data ?? const <BonusTier>[];
              return Column(
                children: tiers
                    .map(
                      (t) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.trending_up),
                          title: Text('Volumen ${t.volume}'),
                          trailing: Text('\$${t.reward.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text('Logros', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          FutureBuilder<List<Achievement>>(
            future: _achsF,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final achs = snap.data ?? const <Achievement>[];
              return Column(
                children: achs.map((a) {
                  final unlocked = a.unlocked;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        unlocked ? Icons.emoji_events : Icons.lock_outline,
                        color: unlocked ? Colors.amber : Colors.white70,
                      ),
                      title: Text(a.title,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(a.description,
                          style:
                              const TextStyle(color: Colors.white70)),
                      trailing: unlocked && a.unlockedAt != null
                          ? Text(
                              '${a.unlockedAt!.day}/${a.unlockedAt!.month}/${a.unlockedAt!.year}',
                              style: const TextStyle(color: Colors.white70),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

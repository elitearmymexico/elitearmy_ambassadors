// lib/core/mock_repos.dart
import 'dart:async';
import 'models.dart';
import 'repos.dart';

// ================= User =================
class MockUserRepo implements UserRepo {
  UserSummary _user = const UserSummary(
    uid: 'u1',
    name: 'Rafael Jauriga',
    rank: 'Cabo',
    code: 'EA-7F2K9Q',
    nextRank: 'Sargento',
    progress: 0.65,
    directs: 7,
    network: 42,
    activeThisMonth: 21,
    photoUrl: null,
    networkName: 'Equipo Alfa',
    notificationsEnabled: true,
  );

  @override
  Future<UserSummary> getSummary() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _user;
  }

  @override
  Future<UserSummary> updateNetworkName(String name) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _user = _user.copyWith(networkName: name);
    return _user;
  }

  @override
  Future<UserSummary> updateNotifications(bool enabled) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _user = _user.copyWith(notificationsEnabled: enabled);
    return _user;
  }

  @override
  Future<UserSummary> updatePhotoUrl(String url) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _user = _user.copyWith(photoUrl: url);
    return _user;
  }
}

// ================= Referrals =================
class MockReferralsRepo implements ReferralsRepo {
  @override
  String buildInviteUrl(String code) =>
      'https://elite-army-mexico.crosshero.site/?ref=$code';
}

// ================= Payouts =================
class MockPayoutsRepo implements PayoutsRepo {
  @override
  Future<PayoutMonth> getByMonth(String yearMonth) async {
    await Future.delayed(const Duration(milliseconds: 180));

    final items = <PayoutItem>[
      PayoutItem(
        id: 't1',
        type: 'direct',
        amount: 100,
        date: DateTime.now().subtract(const Duration(days: 2)),
        source: 'Alta: Juan Pérez',
        status: 'confirmed',
      ),
      PayoutItem(
        id: 't2',
        type: 'bonus',
        amount: 500,
        date: DateTime.now().subtract(const Duration(days: 1)),
        source: 'Volumen 10',
        status: 'pending',
      ),
      PayoutItem(
        id: 't3',
        type: 'payment',
        amount: 600,
        date: DateTime.now(),
        source: 'Pago aplicado (manual)',
        status: 'paid',
      ),
    ];

    return PayoutMonth(
      monthKey: yearMonth,
      total: items.fold(0, (p, e) => p + e.amount),
      status: 'pending',
      items: items,
    );
  }
}

// ================= Network =================
class MockNetworkRepo implements NetworkRepo {
  @override
  Future<NetworkStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 160));
    return const NetworkStats(directs: 7, networkSize: 42, balance: 2500.0);
  }

  @override
  Future<List<Affiliate>> getAffiliates({
    AffiliatesFilter filter = AffiliatesFilter.all,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final all = <Affiliate>[
      Affiliate(
        name: 'Juan Pérez',
        active: true,
        direct: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Affiliate(
        name: 'María López',
        active: false, // INACTIVO
        direct: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      Affiliate(
        name: 'Carlos Ruiz',
        active: true,
        direct: false,
        joinedAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Affiliate(
        name: 'Ana Torres',
        active: false, // INACTIVO
        direct: false,
        joinedAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Affiliate(
        name: 'Luis Hernández',
        active: true,
        direct: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Affiliate(
        name: 'Elena Gómez',
        active: true,
        direct: false,
        joinedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];

    switch (filter) {
      case AffiliatesFilter.direct:
        return all.where((a) => a.direct).toList();
      case AffiliatesFilter.active:
        return all.where((a) => a.active).toList();
      case AffiliatesFilter.all:
      default:
        return all;
    }
  }
}

// ================= Achievements (Bonos/Logros) =================
class MockAchievementsRepo implements AchievementsRepo {
  @override
  Future<List<BonusTier>> getBonusTiers() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return const [
      BonusTier(10, 500),
      BonusTier(20, 1500),
      BonusTier(30, 3000),
      BonusTier(50, 5000),
      BonusTier(100, 10000),
    ];
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      Achievement(
        id: 'a1',
        title: 'Primer directo',
        description: 'Lograste tu primer referido directo.',
        unlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Achievement(
        id: 'a2',
        title: 'Racha 3 meses activo',
        description: 'Mantén tu actividad por 3 meses seguidos.',
        unlocked: false,
        unlockedAt: null,
      ),
      Achievement(
        id: 'a3',
        title: 'Meta 20 del mes',
        description: 'Alcanza 20 activos en un mes.',
        unlocked: false,
        unlockedAt: null,
      ),
    ];
  }
}

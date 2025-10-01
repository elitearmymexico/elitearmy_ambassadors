// lib/core/models.dart
// Modelos base (mock)

class UserSummary {
  final String uid;
  final String name;
  final String rank;
  final String code;
  final String nextRank;
  final double progress;
  final int directs;
  final int network;
  final int activeThisMonth;
  final String? photoUrl;
  final String networkName;
  final bool notificationsEnabled;

  const UserSummary({
    required this.uid,
    required this.name,
    required this.rank,
    required this.code,
    required this.nextRank,
    required this.progress,
    required this.directs,
    required this.network,
    required this.activeThisMonth,
    required this.photoUrl,
    required this.networkName,
    required this.notificationsEnabled,
  });

  UserSummary copyWith({
    String? name,
    String? rank,
    String? code,
    String? nextRank,
    double? progress,
    int? directs,
    int? network,
    int? activeThisMonth,
    String? photoUrl,
    String? networkName,
    bool? notificationsEnabled,
  }) {
    return UserSummary(
      uid: uid,
      name: name ?? this.name,
      rank: rank ?? this.rank,
      code: code ?? this.code,
      nextRank: nextRank ?? this.nextRank,
      progress: progress ?? this.progress,
      directs: directs ?? this.directs,
      network: network ?? this.network,
      activeThisMonth: activeThisMonth ?? this.activeThisMonth,
      photoUrl: photoUrl ?? this.photoUrl,
      networkName: networkName ?? this.networkName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class PayoutMonth {
  final String monthKey;
  final int total;
  final String status;
  final List<PayoutItem> items;
  const PayoutMonth({
    required this.monthKey,
    required this.total,
    required this.status,
    required this.items,
  });
}

class PayoutItem {
  final String id;
  final String type; // direct | bonus | payment
  final int amount;
  final DateTime date;
  final String source;
  final String status; // confirmed | pending | paid
  const PayoutItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.source,
    required this.status,
  });
}

class NetworkStats {
  final int directs;
  final int networkSize;
  final double balance;
  const NetworkStats({
    required this.directs,
    required this.networkSize,
    required this.balance,
  });
}

// ---- Bonos y logros
class BonusTier {
  final int volume;
  final int reward;
  const BonusTier(this.volume, this.reward);
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
    this.unlockedAt,
  });
}

// ---- Afiliados
enum AffiliatesFilter { all, direct, active }

class Affiliate {
  final String name;
  final bool active;
  final bool direct;
  final DateTime joinedAt;
  const Affiliate({
    required this.name,
    required this.active,
    required this.direct,
    required this.joinedAt,
  });
}

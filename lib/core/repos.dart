// Elite Ambassadors – repos.dart (v0.2.1)
// Contratos de repos para User, Network, Payouts, Achievements, Referrals.

import 'models.dart';

abstract class UserRepo {
  Future<UserSummary> getSummary();
  Future<UserSummary> updateNetworkName(String name);
  Future<UserSummary> updateNotifications(bool enabled);
  Future<UserSummary> updatePhotoUrl(String url);
}

abstract class ReferralsRepo {
  String buildInviteUrl(String code);
}

abstract class PayoutsRepo {
  Future<PayoutMonth> getByMonth(String yearMonth);
}

abstract class NetworkRepo {
  Future<NetworkStats> getStats();

  // NUEVO: lista de afiliados (todos/directos/activos)
  Future<List<Affiliate>> getAffiliates({
    AffiliatesFilter filter = AffiliatesFilter.all,
  });
}

abstract class AchievementsRepo {
  Future<List<BonusTier>> getBonusTiers();
  Future<List<Achievement>> getAchievements();
}

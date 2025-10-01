// lib/core/locator.dart
// Service locator (elige Mocks ahora; luego podrás cambiar a Firebase)

import 'repos.dart';
import 'mock_repos.dart';

class Locator {
  static final Locator I = Locator._();
  Locator._();

  late final UserRepo userRepo;
  late final ReferralsRepo referralsRepo;
  late final PayoutsRepo payoutsRepo;
  late final NetworkRepo networkRepo;
  late final AchievementsRepo achievementsRepo;

  /// Llama a esto una sola vez (por ejemplo en main()) para usar los Mocks.
  void useMocks() {
    userRepo = MockUserRepo();
    referralsRepo = MockReferralsRepo();
    payoutsRepo = MockPayoutsRepo();
    networkRepo = MockNetworkRepo();
    achievementsRepo = MockAchievementsRepo();
  }
}

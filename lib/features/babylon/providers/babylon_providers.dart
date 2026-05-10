import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/babylon_service.dart';
import '../data/vault_service.dart';
import '../../../features/auth/data/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

final vaultsProvider = FutureProvider((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <Contribution>[];
  return ref.watch(vaultServiceProvider).getVaults(user.id);
});

final availableChallengesProvider = FutureProvider((ref) {
  return ref.watch(babylonServiceProvider).getAvailableChallenges();
});

final userChallengesProvider = FutureProvider((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return <UserChallenge>[];
  final database = ref.watch(databaseProvider);
  return (database.select(database.userChallenges)..where((t) => t.userId.equals(user.id))).get();
});

final financialScoreProvider = Provider((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.financialScore ?? 0.0;
});

final userLevelProvider = Provider((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.level ?? 'Débutant';
});

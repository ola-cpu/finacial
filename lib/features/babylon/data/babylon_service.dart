import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class BabylonService {
  final AppDatabase database;

  BabylonService(this.database);

  Future<void> updateFinancialScore(int userId) async {
    final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();

    // Simple score calculation based on saving percentage and goals reached
    double score = 0;

    // Factor 1: Saving percentage (0-40 points)
    score += (user.savingPercentage / 50) * 40;

    // Factor 2: Goals progress (0-40 points)
    final goals = await (database.select(database.goals)..where((t) => t.userId.equals(userId))).get();
    if (goals.isNotEmpty) {
      double totalProgress = 0;
      for (var goal in goals) {
        totalProgress += (goal.currentAmount / goal.targetAmount).clamp(0, 1);
      }
      score += (totalProgress / goals.length) * 40;
    }

    // Factor 3: Points from challenges (0-20 points)
    score += (user.points / 1000).clamp(0, 1) * 20;

    score = score.clamp(0, 100);

    // Update level
    String level = 'Débutant';
    if (score >= 90) level = 'Maître financier';
    else if (score >= 70) level = 'Stratège financier';
    else if (score >= 50) level = 'Investisseur';
    else if (score >= 30) level = 'Économe';

    await (database.update(database.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        financialScore: Value(score),
        level: Value(level),
      ),
    );
  }

  Future<void> addPoints(int userId, int points) async {
    final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();
    await (database.update(database.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        points: Value(user.points + points),
      ),
    );
    await updateFinancialScore(userId);
  }

  Future<List<Challenge>> getAvailableChallenges() async {
    return await database.select(database.challenges).get();
  }

  Future<void> joinChallenge(int userId, int challengeId) async {
    final challenge = await (database.select(database.challenges)..where((t) => t.id.equals(challengeId))).getSingle();
    await database.into(database.userChallenges).insert(
      UserChallengesCompanion.insert(
        userId: userId,
        challengeId: challengeId,
        startDate: DateTime.now(),
        endDate: Value(DateTime.now().add(Duration(days: challenge.durationDays))),
      ),
    );
  }
}

final babylonServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return BabylonService(database);
});

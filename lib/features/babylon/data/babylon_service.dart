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

    // Record history
    await database.into(database.financialScoreHistories).insert(
          FinancialScoreHistoriesCompanion.insert(
            userId: userId,
            score: score,
            recordedAt: DateTime.now(),
          ),
        );
  }

  /// READ: Retrieves the financial score history for a user.
  Future<List<FinancialScoreHistory>> getScoreHistory(int userId) async {
    return await (database.select(database.financialScoreHistories)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  /// UPDATE: Resets the financial health of a user.
  Future<void> resetFinancialHealth(int userId) async {
    await (database.update(database.users)..where((t) => t.id.equals(userId))).write(
      const UsersCompanion(
        financialScore: Value(0),
        points: Value(0),
        level: Value('Débutant'),
      ),
    );
    await (database.delete(database.financialScoreHistories)..where((t) => t.userId.equals(userId))).go();
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

  /// CREATE: Adds a new financial challenge.
  Future<void> createChallenge({
    required String title,
    required String description,
    required String type,
    required double targetValue,
    required int durationDays,
    required int rewardPoints,
  }) async {
    await database.into(database.challenges).insert(
          ChallengesCompanion.insert(
            title: title,
            description: description,
            type: type,
            targetValue: targetValue,
            durationDays: durationDays,
            rewardPoints: rewardPoints,
          ),
        );
  }

  /// UPDATE: Modifies an existing challenge.
  Future<void> updateChallenge({
    required int id,
    String? title,
    String? description,
    String? type,
    double? targetValue,
    int? durationDays,
    int? rewardPoints,
  }) async {
    await (database.update(database.challenges)..where((t) => t.id.equals(id))).write(
      ChallengesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        targetValue: targetValue != null ? Value(targetValue) : const Value.absent(),
        durationDays: durationDays != null ? Value(durationDays) : const Value.absent(),
        rewardPoints: rewardPoints != null ? Value(rewardPoints) : const Value.absent(),
      ),
    );
  }

  /// DELETE: Removes a challenge.
  Future<void> deleteChallenge(int id) async {
    await (database.delete(database.challenges)..where((t) => t.id.equals(id))).go();
  }

  /// CREATE: Awards a badge to a user.
  Future<void> awardBadge(int userId, int badgeId) async {
    await database.into(database.userBadges).insert(
          UserBadgesCompanion.insert(
            userId: userId,
            badgeId: badgeId,
            unlockedAt: DateTime.now(),
          ),
        );
  }

  /// READ: Retrieves all badges unlocked by a user.
  Future<List<UserBadge>> getUserBadges(int userId) async {
    return await (database.select(database.userBadges)..where((t) => t.userId.equals(userId))).get();
  }
}

final babylonServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return BabylonService(database);
});

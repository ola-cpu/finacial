import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class GoalService {
  final AppDatabase database;

  GoalService(this.database);

  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    await database.into(database.goals).insert(
          GoalsCompanion.insert(
            title: title,
            targetAmount: targetAmount,
            deadline: deadline,
            syncStatus: const Value(0),
          ),
        );
  }

  Future<void> updateGoal({
    required int id,
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    await (database.update(database.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(
        title: Value(title),
        targetAmount: Value(targetAmount),
        deadline: Value(deadline),
        syncStatus: const Value(0),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    final goals = await database.select(database.goals).get();

    return goals.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'target_amount': e.targetAmount,
      'deadline': e.deadline.toIso8601String(),
    }).toList();
  }
}

final goalServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return GoalService(database);
});

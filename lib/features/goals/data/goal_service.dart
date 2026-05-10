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
    int? userId,
  }) async {
    await database.into(database.goals).insert(
          GoalsCompanion.insert(
            userId: Value(userId),
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
    double? currentAmount,
  }) async {
    await (database.update(database.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(
        title: Value(title),
        targetAmount: Value(targetAmount),
        deadline: Value(deadline),
        currentAmount: currentAmount != null ? Value(currentAmount) : const Value.absent(),
        syncStatus: const Value(0),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getGoals({int? userId}) async {
    final select = database.select(database.goals);
    if (userId != null) select.where((t) => t.userId.equals(userId));
    final goals = await select.get();

    return goals.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'target_amount': e.targetAmount,
      'current_amount': e.currentAmount,
      'deadline': e.deadline.toIso8601String(),
    }).toList();
  }

  Future<void> deleteGoal(int id) async {
    await (database.delete(database.goals)..where((t) => t.id.equals(id))).go();
  }

  Future<Map<String, dynamic>> estimateTimeRemaining(int goalId, int? userId) async {
    final goal = await (database.select(database.goals)..where((t) => t.id.equals(goalId))).getSingle();

    final remainingAmount = goal.targetAmount - goal.currentAmount;
    if (remainingAmount <= 0) return {'months': 0, 'status': 'Complété'};

    // Calculate average monthly savings from history
    final incomesSelect = database.select(database.incomes);
    if (userId != null) incomesSelect.where((t) => t.userId.equals(userId));
    final incomes = await incomesSelect.get();

    final expensesSelect = database.select(database.expenses);
    if (userId != null) expensesSelect.where((t) => t.userId.equals(userId));
    final expenses = await expensesSelect.get();

    if (incomes.isEmpty) return {'months': 999, 'status': 'Besoin de revenus'};

    double totalIncome = incomes.fold(0, (sum, item) => sum + item.amount);
    double totalExpense = expenses.fold(0, (sum, item) => sum + item.amount);

    // Find first transaction date to calculate months elapsed
    DateTime? firstDate;
    for (var i in incomes) {
      if (firstDate == null || i.createdAt.isBefore(firstDate)) firstDate = i.createdAt;
    }

    int monthsElapsed = 1;
    if (firstDate != null) {
      monthsElapsed = (DateTime.now().difference(firstDate).inDays / 30).ceil();
      if (monthsElapsed == 0) monthsElapsed = 1;
    }

    double averageMonthlySavings = (totalIncome - totalExpense) / monthsElapsed;

    if (averageMonthlySavings <= 0) return {'months': 999, 'status': 'Économies insuffisantes'};

    int months = (remainingAmount / averageMonthlySavings).ceil();
    return {
      'months': months,
      'remainingAmount': remainingAmount,
      'status': 'En cours',
    };
  }

  /// UPDATE: Automatically tracks and updates the performance (currentAmount) of a goal.
  /// It sums all incomes and subtracts all expenses for the goal's user to estimate savings,
  /// or could be more specific if goals were linked to categories.
  Future<void> trackPerformance(int goalId) async {
    final goal = await (database.select(database.goals)..where((t) => t.id.equals(goalId))).getSingle();
    if (goal.userId == null) return;

    final incomes = await (database.select(database.incomes)..where((t) => t.userId.equals(goal.userId!))).get();
    final expenses = await (database.select(database.expenses)..where((t) => t.userId.equals(goal.userId!))).get();

    double totalIncome = incomes.fold(0, (sum, item) => sum + item.amount);
    double totalExpense = expenses.fold(0, (sum, item) => sum + item.amount);

    // In this simplified logic, we assume a portion of net savings is allocated to the goal.
    // For a more advanced system, we'd use the Vaults/Contributions.
    final netSavings = totalIncome - totalExpense;

    // Let's assume the user allocates their savingPercentage of net savings to this goal (simplified)
    final user = await (database.select(database.users)..where((t) => t.id.equals(goal.userId!))).getSingle();
    final allocatedAmount = (netSavings * (user.savingPercentage / 100)).clamp(0.0, goal.targetAmount);

    await (database.update(database.goals)..where((t) => t.id.equals(goalId))).write(
      GoalsCompanion(
        currentAmount: Value(allocatedAmount),
      ),
    );
  }
}

final goalServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return GoalService(database);
});

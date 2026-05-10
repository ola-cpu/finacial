import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class BudgetService {
  final AppDatabase database;

  BudgetService(this.database);

  Future<void> addBudget({
    required String category,
    required double monthlyLimit,
  }) async {
    await database.into(database.budgets).insert(
          BudgetsCompanion.insert(
            category: category,
            monthlyLimit: monthlyLimit,
            syncStatus: const Value(0),
          ),
        );
  }

  Future<void> updateBudget({
    required int id,
    required double monthlyLimit,
  }) async {
    await (database.update(database.budgets)..where((t) => t.id.equals(id))).write(
      BudgetsCompanion(
        monthlyLimit: Value(monthlyLimit),
        syncStatus: const Value(0),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final budgets = await database.select(database.budgets).get();

    return budgets.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'category': e.category,
      'monthly_limit': e.monthlyLimit,
    }).toList();
  }
}

final budgetServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return BudgetService(database);
});

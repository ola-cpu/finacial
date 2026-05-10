import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class ExpenseService {
  final AppDatabase database;

  ExpenseService(this.database);

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
  }) async {
    final now = DateTime.now();

    await database.into(database.expenses).insert(
          ExpensesCompanion.insert(
            title: title,
            amount: amount,
            category: category,
            createdAt: now,
            syncStatus: const Value(0),
          ),
        );
  }

  Future<void> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
  }) async {
    await (database.update(database.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        title: Value(title),
        amount: Value(amount),
        category: Value(category),
        syncStatus: const Value(0),
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    await (database.delete(database.expenses)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final expenses = await database.select(database.expenses).get();

    return expenses.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'created_at': e.createdAt.toIso8601String(),
    }).toList();
  }
}

final expenseServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return ExpenseService(database);
});

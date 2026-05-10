import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/automation_service.dart';

class ExpenseService {
  final AppDatabase database;
  final ProviderContainer? container;

  ExpenseService(this.database, [this.container]);

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    int? userId,
    String? tags,
  }) async {
    final now = DateTime.now();

    // Automatic Categorization logic
    String finalCategory = category;

    // Only suggest category if current category is 'Autre'
    if (category == 'Autre') {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('uber') || lowerTitle.contains('taxi')) {
        finalCategory = 'Transport';
      } else if (lowerTitle.contains('resto') || lowerTitle.contains('manger')) {
        finalCategory = 'Alimentation';
      }
    }

    await database.into(database.expenses).insert(
          ExpensesCompanion.insert(
            userId: Value(userId),
            title: title,
            amount: amount,
            category: finalCategory,
            tags: Value(tags),
            createdAt: now,
            syncStatus: const Value(0),
          ),
        );

    if (container != null && userId != null) {
      await container!.read(automationServiceProvider).handleExpenseAdded(userId, finalCategory, amount);
    }
  }

  Future<void> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String? tags,
  }) async {
    final expense = await (database.select(database.expenses)..where((t) => t.id.equals(id))).getSingle();

    await (database.update(database.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        title: Value(title),
        amount: Value(amount),
        category: Value(category),
        tags: Value(tags),
        syncStatus: const Value(0),
      ),
    );

    if (container != null && expense.userId != null) {
      await container!.read(automationServiceProvider).handleTransactionChanged(expense.userId!);
    }
  }

  Future<void> deleteExpense(int id) async {
    final expense = await (database.select(database.expenses)..where((t) => t.id.equals(id))).getSingle();
    await (database.delete(database.expenses)..where((t) => t.id.equals(id))).go();

    if (container != null && expense.userId != null) {
      await container!.read(automationServiceProvider).handleTransactionChanged(expense.userId!);
    }
  }

  Future<List<Map<String, dynamic>>> getExpenses({
    int? userId,
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final select = database.select(database.expenses);

    if (userId != null) select.where((t) => t.userId.equals(userId));
    if (query != null && query.isNotEmpty) {
      select.where((t) => t.title.contains(query) | t.tags.contains(query));
    }
    if (category != null && category != 'Tous') {
      select.where((t) => t.category.equals(category));
    }
    if (startDate != null) {
      select.where((t) => t.createdAt.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      select.where((t) => t.createdAt.isSmallerOrEqualValue(endDate));
    }

    final expenses = await select.get();

    return expenses.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'tags': e.tags,
      'created_at': e.createdAt.toIso8601String(),
    }).toList();
  }
}

final expenseServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return ExpenseService(database, ref.container);
});

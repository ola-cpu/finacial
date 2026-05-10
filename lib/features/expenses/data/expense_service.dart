import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/sync_service.dart';

class ExpenseService {
  final SupabaseClient supabase;
  final AppDatabase database;
  final SyncService syncService;

  ExpenseService(this.supabase, this.database, this.syncService);

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
            syncStatus: const Value(1), // pending_insert
          ),
        );

    _triggerSync();
  }

  Future<void> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
  }) async {
    final existing = await (database.select(database.expenses)..where((t) => t.id.equals(id))).getSingle();

    await (database.update(database.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        title: Value(title),
        amount: Value(amount),
        category: Value(category),
        syncStatus: Value(existing.remoteId == null ? 1 : 2), // remain pending_insert if not yet synced, otherwise pending_update
      ),
    );

    _triggerSync();
  }

  Future<void> deleteExpense(int id) async {
    final existing = await (database.select(database.expenses)..where((t) => t.id.equals(id))).getSingle();

    if (existing.remoteId == null) {
      // Never synced, just delete locally
      await (database.delete(database.expenses)..where((t) => t.id.equals(id))).go();
    } else {
      // Mark for deletion
      await (database.update(database.expenses)..where((t) => t.id.equals(id))).write(
        const ExpensesCompanion(syncStatus: Value(3)),
      );
    }

    _triggerSync();
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final expenses = await (database.select(database.expenses)
          ..where((t) => t.syncStatus.isSmallerThanValue(3)))
        .get();

    return expenses.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'created_at': e.createdAt.toIso8601String(),
    }).toList();
  }

  void _triggerSync() {
    if (supabase.auth.currentUser != null) {
      syncService.pushChanges();
    }
  }
}

final expenseServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  final database = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return ExpenseService(supabase, database, syncService);
});

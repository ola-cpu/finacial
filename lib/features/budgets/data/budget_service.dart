import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/sync_service.dart';

class BudgetService {
  final SupabaseClient supabase;
  final AppDatabase database;
  final SyncService syncService;

  BudgetService(this.supabase, this.database, this.syncService);

  Future<void> addBudget({
    required String category,
    required double monthlyLimit,
  }) async {
    await database.into(database.budgets).insert(
          BudgetsCompanion.insert(
            category: category,
            monthlyLimit: monthlyLimit,
            syncStatus: const Value(1),
          ),
        );

    _triggerSync();
  }

  Future<void> updateBudget({
    required int id,
    required double monthlyLimit,
  }) async {
    final existing = await (database.select(database.budgets)..where((t) => t.id.equals(id))).getSingle();

    await (database.update(database.budgets)..where((t) => t.id.equals(id))).write(
      BudgetsCompanion(
        monthlyLimit: Value(monthlyLimit),
        syncStatus: Value(existing.remoteId == null ? 1 : 2),
      ),
    );

    _triggerSync();
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final budgets = await (database.select(database.budgets)
          ..where((t) => t.syncStatus.isSmallerThanValue(3)))
        .get();

    return budgets.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'category': e.category,
      'monthly_limit': e.monthlyLimit,
    }).toList();
  }

  void _triggerSync() {
    if (supabase.auth.currentUser != null) {
      syncService.pushChanges();
    }
  }
}

final budgetServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  final database = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return BudgetService(supabase, database, syncService);
});

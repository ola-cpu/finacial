import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/sync_service.dart';

class IncomeService {
  final SupabaseClient supabase;
  final AppDatabase database;
  final SyncService syncService;

  IncomeService(this.supabase, this.database, this.syncService);

  Future<void> addIncome({
    required String title,
    required double amount,
    required String category,
  }) async {
    final now = DateTime.now();

    await database.into(database.incomes).insert(
          IncomesCompanion.insert(
            title: title,
            amount: amount,
            category: category,
            createdAt: now,
            syncStatus: const Value(1),
          ),
        );

    _triggerSync();
  }

  Future<void> updateIncome({
    required int id,
    required String title,
    required double amount,
    required String category,
  }) async {
    final existing = await (database.select(database.incomes)..where((t) => t.id.equals(id))).getSingle();

    await (database.update(database.incomes)..where((t) => t.id.equals(id))).write(
      IncomesCompanion(
        title: Value(title),
        amount: Value(amount),
        category: Value(category),
        syncStatus: Value(existing.remoteId == null ? 1 : 2),
      ),
    );

    _triggerSync();
  }

  Future<void> deleteIncome(int id) async {
    final existing = await (database.select(database.incomes)..where((t) => t.id.equals(id))).getSingle();

    if (existing.remoteId == null) {
      await (database.delete(database.incomes)..where((t) => t.id.equals(id))).go();
    } else {
      await (database.update(database.incomes)..where((t) => t.id.equals(id))).write(
        const IncomesCompanion(syncStatus: Value(3)),
      );
    }

    _triggerSync();
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final incomes = await (database.select(database.incomes)
          ..where((t) => t.syncStatus.isSmallerThanValue(3)))
        .get();

    return incomes.map((e) => {
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

final incomeServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  final database = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return IncomeService(supabase, database, syncService);
});

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/sync_service.dart';

class GoalService {
  final SupabaseClient supabase;
  final AppDatabase database;
  final SyncService syncService;

  GoalService(this.supabase, this.database, this.syncService);

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
            syncStatus: const Value(1),
          ),
        );

    _triggerSync();
  }

  Future<void> updateGoal({
    required int id,
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final existing = await (database.select(database.goals)..where((t) => t.id.equals(id))).getSingle();

    await (database.update(database.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(
        title: Value(title),
        targetAmount: Value(targetAmount),
        deadline: Value(deadline),
        syncStatus: Value(existing.remoteId == null ? 1 : 2),
      ),
    );

    _triggerSync();
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    final goals = await (database.select(database.goals)
          ..where((t) => t.syncStatus.isSmallerThanValue(3)))
        .get();

    return goals.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'target_amount': e.targetAmount,
      'deadline': e.deadline.toIso8601String(),
    }).toList();
  }

  void _triggerSync() {
    if (supabase.auth.currentUser != null) {
      syncService.pushChanges();
    }
  }
}

final goalServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  final database = ref.watch(databaseProvider);
  final syncService = ref.watch(syncServiceProvider);
  return GoalService(supabase, database, syncService);
});

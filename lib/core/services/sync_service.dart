import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class SyncService {
  final SupabaseClient supabase;
  final AppDatabase database;

  SyncService(this.supabase, this.database);

  Future<void> syncAll() async {
    await pushChanges();
    await pullChanges();
  }

  Future<void> pushChanges() async {
    await _pushExpenses();
    await _pushIncomes();
    await _pushBudgets();
    await _pushGoals();
  }

  Future<void> pullChanges() async {
    await _pullExpenses();
    await _pullIncomes();
    await _pullBudgets();
    await _pullGoals();
  }

  // --- Expenses ---
  Future<void> _pushExpenses() async {
    final pending = await (database.select(database.expenses)
          ..where((t) => t.syncStatus.isBiggerThanValue(0)))
        .get();

    for (final item in pending) {
      try {
        if (item.syncStatus == 1) {
          final response = await supabase.from('expenses').insert({
            'user_id': supabase.auth.currentUser!.id,
            'title': item.title,
            'amount': item.amount,
            'category': item.category,
            'created_at': item.createdAt.toIso8601String(),
          }).select('id').single();

          await (database.update(database.expenses)
                ..where((t) => t.id.equals(item.id)))
              .write(ExpensesCompanion(
            remoteId: Value(response['id'].toString()),
            syncStatus: const Value(0),
          ));
        } else if (item.syncStatus == 2) {
          await supabase.from('expenses').update({
            'title': item.title,
            'amount': item.amount,
            'category': item.category,
          }).eq('id', item.remoteId!);

          await (database.update(database.expenses)
                ..where((t) => t.id.equals(item.id)))
              .write(const ExpensesCompanion(syncStatus: Value(0)));
        } else if (item.syncStatus == 3) {
          if (item.remoteId != null) {
            await supabase.from('expenses').delete().eq('id', item.remoteId!);
          }
          await (database.delete(database.expenses)..where((t) => t.id.equals(item.id))).go();
        }
      } catch (e) {
        print('Error pushing expense ${item.id}: $e');
      }
    }
  }

  Future<void> _pullExpenses() async {
    try {
      final remoteData = await supabase.from('expenses').select();
      final remoteIds = remoteData.map((e) => e['id'].toString()).toSet();

      // Handle remote deletions: delete local records that are synced but not in remoteIds
      await (database.delete(database.expenses)
            ..where((t) => t.syncStatus.equals(0) & t.remoteId.isNotIn(remoteIds)))
          .go();

      for (final raw in remoteData) {
        final remoteId = raw['id'].toString();
        await database.into(database.expenses).insertOnConflictUpdate(
              ExpensesCompanion.insert(
                remoteId: Value(remoteId),
                title: raw['title'],
                amount: (raw['amount'] as num).toDouble(),
                category: raw['category'],
                createdAt: DateTime.parse(raw['created_at']),
                syncStatus: const Value(0),
              ),
            );
      }
    } catch (e) {
      print('Error pulling expenses: $e');
    }
  }

  // --- Incomes ---
  Future<void> _pushIncomes() async {
    final pending = await (database.select(database.incomes)
          ..where((t) => t.syncStatus.isBiggerThanValue(0)))
        .get();

    for (final item in pending) {
      try {
        if (item.syncStatus == 1) {
          final response = await supabase.from('incomes').insert({
            'user_id': supabase.auth.currentUser!.id,
            'title': item.title,
            'amount': item.amount,
            'category': item.category,
            'created_at': item.createdAt.toIso8601String(),
          }).select('id').single();

          await (database.update(database.incomes)
                ..where((t) => t.id.equals(item.id)))
              .write(IncomesCompanion(
            remoteId: Value(response['id'].toString()),
            syncStatus: const Value(0),
          ));
        } else if (item.syncStatus == 2) {
          await supabase.from('incomes').update({
            'title': item.title,
            'amount': item.amount,
            'category': item.category,
          }).eq('id', item.remoteId!);

          await (database.update(database.incomes)
                ..where((t) => t.id.equals(item.id)))
              .write(const IncomesCompanion(syncStatus: Value(0)));
        } else if (item.syncStatus == 3) {
          if (item.remoteId != null) {
            await supabase.from('incomes').delete().eq('id', item.remoteId!);
          }
          await (database.delete(database.incomes)..where((t) => t.id.equals(item.id))).go();
        }
      } catch (e) {
        print('Error pushing income ${item.id}: $e');
      }
    }
  }

  Future<void> _pullIncomes() async {
    try {
      final remoteData = await supabase.from('incomes').select();
      final remoteIds = remoteData.map((e) => e['id'].toString()).toSet();

      await (database.delete(database.incomes)
            ..where((t) => t.syncStatus.equals(0) & t.remoteId.isNotIn(remoteIds)))
          .go();

      for (final raw in remoteData) {
        final remoteId = raw['id'].toString();
        await database.into(database.incomes).insertOnConflictUpdate(
              IncomesCompanion.insert(
                remoteId: Value(remoteId),
                title: raw['title'],
                amount: (raw['amount'] as num).toDouble(),
                category: raw['category'],
                createdAt: DateTime.parse(raw['created_at']),
                syncStatus: const Value(0),
              ),
            );
      }
    } catch (e) {
      print('Error pulling incomes: $e');
    }
  }

  // --- Budgets ---
  Future<void> _pushBudgets() async {
    final pending = await (database.select(database.budgets)
          ..where((t) => t.syncStatus.isBiggerThanValue(0)))
        .get();

    for (final item in pending) {
      try {
        if (item.syncStatus == 1) {
          final response = await supabase.from('budgets').insert({
            'user_id': supabase.auth.currentUser!.id,
            'category': item.category,
            'monthly_limit': item.monthlyLimit,
          }).select('id').single();

          await (database.update(database.budgets)
                ..where((t) => t.id.equals(item.id)))
              .write(BudgetsCompanion(
            remoteId: Value(response['id'].toString()),
            syncStatus: const Value(0),
          ));
        } else if (item.syncStatus == 2) {
          await supabase.from('budgets').update({
            'monthly_limit': item.monthlyLimit,
          }).eq('id', item.remoteId!);

          await (database.update(database.budgets)
                ..where((t) => t.id.equals(item.id)))
              .write(const BudgetsCompanion(syncStatus: Value(0)));
        } else if (item.syncStatus == 3) {
          if (item.remoteId != null) {
            await supabase.from('budgets').delete().eq('id', item.remoteId!);
          }
          await (database.delete(database.budgets)..where((t) => t.id.equals(item.id))).go();
        }
      } catch (e) {
        print('Error pushing budget ${item.id}: $e');
      }
    }
  }

  Future<void> _pullBudgets() async {
    try {
      final remoteData = await supabase.from('budgets').select();
      final remoteIds = remoteData.map((e) => e['id'].toString()).toSet();

      await (database.delete(database.budgets)
            ..where((t) => t.syncStatus.equals(0) & t.remoteId.isNotIn(remoteIds)))
          .go();

      for (final raw in remoteData) {
        final remoteId = raw['id'].toString();
        await database.into(database.budgets).insertOnConflictUpdate(
              BudgetsCompanion.insert(
                remoteId: Value(remoteId),
                category: raw['category'],
                monthlyLimit: (raw['monthly_limit'] as num).toDouble(),
                syncStatus: const Value(0),
              ),
            );
      }
    } catch (e) {
      print('Error pulling budgets: $e');
    }
  }

  // --- Goals ---
  Future<void> _pushGoals() async {
    final pending = await (database.select(database.goals)
          ..where((t) => t.syncStatus.isBiggerThanValue(0)))
        .get();

    for (final item in pending) {
      try {
        if (item.syncStatus == 1) {
          final response = await supabase.from('goals').insert({
            'user_id': supabase.auth.currentUser!.id,
            'title': item.title,
            'target_amount': item.targetAmount,
            'deadline': item.deadline.toIso8601String(),
          }).select('id').single();

          await (database.update(database.goals)
                ..where((t) => t.id.equals(item.id)))
              .write(GoalsCompanion(
            remoteId: Value(response['id'].toString()),
            syncStatus: const Value(0),
          ));
        } else if (item.syncStatus == 2) {
          await supabase.from('goals').update({
            'title': item.title,
            'target_amount': item.targetAmount,
            'deadline': item.deadline.toIso8601String(),
          }).eq('id', item.remoteId!);

          await (database.update(database.goals)
                ..where((t) => t.id.equals(item.id)))
              .write(const GoalsCompanion(syncStatus: Value(0)));
        } else if (item.syncStatus == 3) {
          if (item.remoteId != null) {
            await supabase.from('goals').delete().eq('id', item.remoteId!);
          }
          await (database.delete(database.goals)..where((t) => t.id.equals(item.id))).go();
        }
      } catch (e) {
        print('Error pushing goal ${item.id}: $e');
      }
    }
  }

  Future<void> _pullGoals() async {
    try {
      final remoteData = await supabase.from('goals').select();
      final remoteIds = remoteData.map((e) => e['id'].toString()).toSet();

      await (database.delete(database.goals)
            ..where((t) => t.syncStatus.equals(0) & t.remoteId.isNotIn(remoteIds)))
          .go();

      for (final raw in remoteData) {
        final remoteId = raw['id'].toString();
        await database.into(database.goals).insertOnConflictUpdate(
              GoalsCompanion.insert(
                remoteId: Value(remoteId),
                title: raw['title'],
                targetAmount: (raw['target_amount'] as num).toDouble(),
                deadline: DateTime.parse(raw['deadline']),
                syncStatus: const Value(0),
              ),
            );
      }
    } catch (e) {
      print('Error pulling goals: $e');
    }
  }
}

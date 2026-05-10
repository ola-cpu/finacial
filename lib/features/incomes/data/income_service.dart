import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../babylon/data/vault_service.dart';

class IncomeService {
  final AppDatabase database;
  final VaultService? vaultService;

  IncomeService(this.database, [this.vaultService]);

  Future<void> addIncome({
    required String title,
    required double amount,
    required String category,
    int? userId,
  }) async {
    final now = DateTime.now();

    await database.into(database.incomes).insert(
          IncomesCompanion.insert(
            userId: Value(userId),
            title: title,
            amount: amount,
            category: category,
            createdAt: now,
            syncStatus: const Value(0),
          ),
        );

    if (vaultService != null && userId != null) {
      await vaultService!.distributeIncome(userId, amount);
    }
  }

  Future<void> updateIncome({
    required int id,
    required String title,
    required double amount,
    required String category,
  }) async {
    await (database.update(database.incomes)..where((t) => t.id.equals(id))).write(
      IncomesCompanion(
        title: Value(title),
        amount: Value(amount),
        category: Value(category),
        syncStatus: const Value(0),
      ),
    );
  }

  Future<void> deleteIncome(int id) async {
    await (database.delete(database.incomes)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final incomes = await database.select(database.incomes).get();

    return incomes.map((e) => {
      'id': e.id,
      'remote_id': e.remoteId,
      'title': e.title,
      'amount': e.amount,
      'category': e.category,
      'created_at': e.createdAt.toIso8601String(),
    }).toList();
  }
}

final incomeServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  final vaultService = ref.watch(vaultServiceProvider);
  return IncomeService(database, vaultService);
});

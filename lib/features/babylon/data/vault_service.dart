import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class VaultService {
  final AppDatabase database;

  VaultService(this.database);

  Future<List<Contribution>> getVaults(int userId) async {
    return await (database.select(database.contributions)..where((t) => t.userId.equals(userId))).get();
  }

  Future<void> createDefaultVaults(int userId) async {
    final defaultVaults = [
      {'title': 'Épargne', 'percentage': 10.0, 'type': 'savings'},
      {'title': 'Investissements', 'percentage': 20.0, 'type': 'investment'},
      {'title': 'Urgences', 'percentage': 10.0, 'type': 'emergency'},
      {'title': 'Projets', 'percentage': 10.0, 'type': 'project'},
      {'title': 'Business', 'percentage': 10.0, 'type': 'business'},
      {'title': 'Formation', 'percentage': 5.0, 'type': 'formation'},
    ];

    for (var vault in defaultVaults) {
      await database.into(database.contributions).insert(
        ContributionsCompanion.insert(
          userId: Value(userId),
          title: vault['title'] as String,
          percentage: vault['percentage'] as double,
          type: Value(vault['type'] as String),
        ),
      );
    }
  }

  Future<void> distributeIncome(int userId, double amount) async {
    final vaults = await getVaults(userId);
    final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();

    // Always pay yourself first - minimum user.savingPercentage (default 10%)
    // If no vaults are set up, we'll just skip for now, but usually they are created at signup.

    for (var vault in vaults) {
      final contributionAmount = amount * (vault.percentage / 100);
      await (database.update(database.contributions)..where((t) => t.id.equals(vault.id))).write(
        ContributionsCompanion(
          totalAmount: Value(vault.totalAmount + contributionAmount),
          lastCalculationDate: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> updateVaultPercentage(int vaultId, double newPercentage) async {
    await (database.update(database.contributions)..where((t) => t.id.equals(vaultId))).write(
      ContributionsCompanion(
        percentage: Value(newPercentage),
      ),
    );
  }
}

final vaultServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return VaultService(database);
});

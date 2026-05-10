import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class VaultService {
  final AppDatabase database;

  VaultService(this.database);

  Future<List<Contribution>> getVaults(int? userId) async {
    final query = database.select(database.contributions);
    if (userId != null) {
      query.where((t) => t.userId.equals(userId));
    } else {
      query.where((t) => t.userId.isNull());
    }
    return await query.get();
  }

  Future<void> createDefaultVaults(int? userId) async {
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

  Future<void> distributeIncome(int? userId, double amount) async {
    final vaults = await getVaults(userId);
    double savingPercentage = 10.0;

    if (userId != null) {
      final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();
      savingPercentage = user.savingPercentage;
    }

    // Always pay yourself first - minimum savingPercentage (default 10%)
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

  /// CREATE: Creates a new vault (contribution) for a user.
  Future<void> createVault({
    int? userId,
    required String title,
    required double percentage,
    required String type,
    double targetAmount = 1000000,
  }) async {
    if (percentage < 0 || percentage > 100) {
      throw ArgumentError('Le pourcentage doit être compris entre 0 et 100');
    }

    await database.into(database.contributions).insert(
          ContributionsCompanion.insert(
            userId: Value(userId),
            title: title,
            percentage: percentage,
            type: Value(type),
            targetAmount: Value(targetAmount),
          ),
        );
  }

  /// READ: Already implemented in getVaults

  /// UPDATE: Modifies the percentage of a vault with validation.
  Future<void> updateVaultPercentage(int vaultId, double newPercentage) async {
    if (newPercentage < 0 || newPercentage > 100) {
      throw ArgumentError('Le pourcentage doit être compris entre 0 et 100');
    }

    await (database.update(database.contributions)..where((t) => t.id.equals(vaultId))).write(
      ContributionsCompanion(
        percentage: Value(newPercentage),
      ),
    );
  }

  /// UPDATE: Modifies general vault information.
  Future<void> updateVault({
    required int vaultId,
    String? title,
    double? targetAmount,
    String? type,
  }) async {
    await (database.update(database.contributions)..where((t) => t.id.equals(vaultId))).write(
      ContributionsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        targetAmount: targetAmount != null ? Value(targetAmount) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
      ),
    );
  }

  /// DELETE: Removes a vault from the database.
  Future<void> deleteVault(int vaultId) async {
    await (database.delete(database.contributions)..where((t) => t.id.equals(vaultId))).go();
  }
}

final vaultServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return VaultService(database);
});

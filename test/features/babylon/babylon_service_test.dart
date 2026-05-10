import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/features/babylon/data/babylon_service.dart';
import 'package:finance_app/features/babylon/data/vault_service.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase database;
  late BabylonService babylonService;
  late VaultService vaultService;

  setUp(() {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    babylonService = BabylonService(database);
    vaultService = VaultService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('createDefaultVaults creates 6 vaults', () async {
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test@test.com',
        password: 'password',
        name: const Value('Test User'),
        createdAt: DateTime.now(),
      ),
    );

    await vaultService.createDefaultVaults(userId);
    final vaults = await vaultService.getVaults(userId);

    expect(vaults.length, 6);
    expect(vaults.any((v) => v.type == 'savings'), isTrue);
  });

  test('distributeIncome updates vault amounts', () async {
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test2@test.com',
        password: 'password',
        name: const Value('Test User 2'),
        createdAt: DateTime.now(),
      ),
    );

    await vaultService.createDefaultVaults(userId);
    await vaultService.distributeIncome(userId, 1000);

    final vaults = await vaultService.getVaults(userId);
    final savingsVault = vaults.firstWhere((v) => v.type == 'savings');

    // 10% of 1000 is 100
    expect(savingsVault.totalAmount, 100.0);
  });

  test('updateFinancialScore calculates level correctly', () async {
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test3@test.com',
        password: 'password',
        name: const Value('Test User 3'),
        createdAt: DateTime.now(),
        savingPercentage: const Value(20.0), // 20/50 * 40 = 16 points
      ),
    );

    await babylonService.updateFinancialScore(userId);

    final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();
    expect(user.financialScore, 16.0);
    expect(user.level, 'Débutant'); // < 30

    // Add points
    await babylonService.addPoints(userId, 1000); // +20 points = 36 points

    final updatedUser = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();
    expect(updatedUser.financialScore, 36.0);
    expect(updatedUser.level, 'Économe'); // 30 <= score < 50
  });
}

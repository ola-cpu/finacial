import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/features/babylon/data/vault_service.dart';
import 'package:finance_app/features/incomes/data/income_service.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase database;
  late VaultService vaultService;
  late IncomeService incomeService;

  setUp(() {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    vaultService = VaultService(database);
    incomeService = IncomeService(database, vaultService);
  });

  tearDown(() async {
    await database.close();
  });

  test('Adding income automatically distributes to vaults', () async {
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test@test.com',
        password: 'password',
        name: const Value('Test User'),
        createdAt: DateTime.now(),
      ),
    );

    await vaultService.createDefaultVaults(userId);

    await incomeService.addIncome(
      title: 'Salaire',
      amount: 5000,
      category: 'Salaire',
      userId: userId,
    );

    final vaults = await vaultService.getVaults(userId);
    final savingsVault = vaults.firstWhere((v) => v.type == 'savings');
    final investmentVault = vaults.firstWhere((v) => v.type == 'investment');

    // 10% of 5000 is 500
    expect(savingsVault.totalAmount, 500.0);
    // 20% of 5000 is 1000
    expect(investmentVault.totalAmount, 1000.0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/providers/database_provider.dart';
import 'package:finance_app/core/services/automation_service.dart';
import 'package:finance_app/core/services/notification_service.dart';
import 'package:finance_app/features/babylon/data/vault_service.dart';
import 'package:finance_app/features/babylon/data/babylon_service.dart';
import 'package:finance_app/features/budgets/data/budget_service.dart';
import 'package:finance_app/features/goals/data/goal_service.dart';
import 'package:finance_app/features/expenses/data/expense_service.dart';
import 'package:finance_app/features/incomes/data/income_service.dart';
import 'package:finance_app/features/analytics/data/analytics_service.dart';

void main() {
  late AppDatabase database;
  late NotificationService notificationService;
  late VaultService vaultService;
  late BabylonService babylonService;
  late BudgetService budgetService;
  late GoalService goalService;
  late AnalyticsService analyticsService;
  late ExpenseService expenseService;
  late IncomeService incomeService;
  late AutomationService automationService;
  late ProviderContainer container;

  setUp(() async {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    notificationService = NotificationService(database);
    vaultService = VaultService(database);
    babylonService = BabylonService(database);
    budgetService = BudgetService(database);
    goalService = GoalService(database);
    expenseService = ExpenseService(database);
    incomeService = IncomeService(database, vaultService);
    analyticsService = AnalyticsService(database, budgetService, goalService);

    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(database),
      notificationServiceProvider.overrideWithValue(notificationService),
      vaultServiceProvider.overrideWithValue(vaultService),
      babylonServiceProvider.overrideWithValue(babylonService),
      budgetServiceProvider.overrideWithValue(budgetService),
      goalServiceProvider.overrideWithValue(goalService),
      analyticsServiceProvider.overrideWithValue(analyticsService),
    ]);

    automationService = container.read(automationServiceProvider);

    incomeService = IncomeService(database, vaultService, container);
    expenseService = ExpenseService(database, container);
  });

  tearDown(() async {
    await database.close();
  });

  test('Adding income triggers vault distribution and notifications', () async {
    // 1. Create a user
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test@example.com',
        password: 'password',
        name: const Value('Test User'),
        createdAt: DateTime.now(),
      ),
    );

    // 2. Setup default vaults
    await vaultService.createDefaultVaults(userId);

    // 3. Add income
    await incomeService.addIncome(
      title: 'Salaire',
      amount: 500000,
      category: 'Salaire',
      userId: userId,
    );

    // 4. Verify vaults were updated
    final vaults = await vaultService.getVaults(userId);
    final totalInVaults = vaults.fold(0.0, (sum, v) => sum + v.totalAmount);
    expect(totalInVaults, greaterThan(0));

    // 5. Verify notification was sent
    final notifications = await notificationService.getNotifications(userId);
    expect(notifications.any((n) => n.title == 'Revenu Réparti'), isTrue);

    // 6. Verify financial score updated
    final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();
    expect(user.financialScore, greaterThan(0));
  });

  test('Adding expense triggers budget alerts', () async {
     // 1. Create a user
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test@example.com',
        password: 'password',
        name: const Value('Test User'),
        createdAt: DateTime.now(),
      ),
    );

    // 2. Setup budget
    await budgetService.addBudget(category: 'Alimentation', monthlyLimit: 50000);

    // 3. Add expense exceeding budget
    final expenseServiceWithAutomation = ExpenseService(database, container);
    await expenseServiceWithAutomation.addExpense(
      title: 'Course',
      amount: 60000,
      category: 'Alimentation',
      userId: userId,
    );

    // 4. Verify alert notification
    final notifications = await notificationService.getNotifications(userId);
    expect(notifications.any((n) => n.title == 'Budget Dépassé'), isTrue);
  });
}

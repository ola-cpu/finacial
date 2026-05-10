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

  test('Updating and deleting transactions triggers automation (score and goals)', () async {
    // 1. Create a user
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test@example.com',
        password: 'password',
        name: const Value('Test User'),
        createdAt: DateTime.now(),
      ),
    );

    // 2. Setup a goal
    await goalService.addGoal(
      userId: userId,
      title: 'Epargne',
      targetAmount: 100000,
      deadline: DateTime.now().add(const Duration(days: 365)),
    );

    // 3. Add income
    await incomeService.addIncome(
      title: 'Salaire',
      amount: 1000000,
      category: 'Salaire',
      userId: userId,
    );

    // 4. Verify goal progress (10% of 1M = 100k, so 100% of 100k goal)
    var goals = await goalService.getGoals(userId: userId);
    expect(goals.first['current_amount'], 100000.0);

    // 5. Update income (decrease)
    final incomes = await database.select(database.incomes).get();
    await incomeService.updateIncome(
      id: incomes.first.id,
      title: 'Salaire Réduit',
      amount: 500000,
      category: 'Salaire',
    );

    // 6. Verify goal progress updated (10% of 500k = 50k)
    goals = await goalService.getGoals(userId: userId);
    expect(goals.first['current_amount'], 50000.0);

    // 7. Delete income
    await incomeService.deleteIncome(incomes.first.id);

    // 8. Verify goal progress reset to 0
    goals = await goalService.getGoals(userId: userId);
    expect(goals.first['current_amount'], 0.0);
  });

  test('Challenges progress is updated automatically', () async {
     // 1. Create a user
    final userId = await database.into(database.users).insert(
      UsersCompanion.insert(
        email: 'test@example.com',
        password: 'password',
        name: const Value('Test User'),
        createdAt: DateTime.now(),
      ),
    );

    // 2. Create a challenge
    final challengeId = await database.into(database.challenges).insert(
      ChallengesCompanion.insert(
        title: 'Défi Epargne',
        description: 'Epargnez 100k',
        type: 'saving',
        targetValue: 100000,
        durationDays: 30,
        rewardPoints: 100,
      ),
    );

    // 3. Join challenge
    await babylonService.joinChallenge(userId, challengeId);

    // 4. Add income (Net savings = 200k)
    await incomeService.addIncome(
      title: 'Freelance',
      amount: 200000,
      category: 'Business',
      userId: userId,
    );

    // 5. Verify challenge progress (200k / 100k = 200%, clamped to 100%)
    final userChallenges = await (database.select(database.userChallenges)..where((t) => t.userId.equals(userId))).get();
    expect(userChallenges.first.progress, 1.0);
    expect(userChallenges.first.status, 'completed');

    // 6. Verify points and notification
    final user = await (database.select(database.users)..where((t) => t.id.equals(userId))).getSingle();
    expect(user.points, 100);

    final notifications = await notificationService.getNotifications(userId);
    expect(notifications.any((n) => n.title == 'Défi Relevé !'), isTrue);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';
import '../../features/babylon/data/vault_service.dart';
import '../../features/babylon/data/babylon_service.dart';
import '../../features/budgets/data/budget_service.dart';
import 'package:drift/drift.dart';
import '../../features/goals/data/goal_service.dart';
import '../../features/analytics/data/analytics_service.dart';

class AutomationService {
  final AppDatabase database;
  final NotificationService notificationService;
  final VaultService vaultService;
  final BabylonService babylonService;
  final BudgetService budgetService;
  final GoalService goalService;
  final AnalyticsService analyticsService;

  AutomationService({
    required this.database,
    required this.notificationService,
    required this.vaultService,
    required this.babylonService,
    required this.budgetService,
    required this.goalService,
    required this.analyticsService,
  });

  Future<void> handleIncomeAdded(int? userId, double amount) async {
    if (userId == null) return;

    // 1. Distribute to vaults
    await vaultService.distributeIncome(userId, amount);

    // 2. Update financial score
    await babylonService.updateFinancialScore(userId);

    // 3. Check goals and notify if reached
    final goals = await goalService.getGoals(userId: userId);
    for (var goal in goals) {
      await goalService.trackPerformance(goal['id']);
      final updatedGoal = (await goalService.getGoals(userId: userId)).firstWhere((g) => g['id'] == goal['id']);
      if (updatedGoal['current_amount'] >= updatedGoal['target_amount']) {
        await notificationService.sendCongratulation(
          userId: userId,
          title: 'Objectif Atteint !',
          body: 'Félicitations ! Vous avez atteint votre objectif : ${goal['title']}.',
        );
      }
    }

    // 4. Proactive advice
    final advice = await analyticsService.generateAutomatedAdvice();
    if (advice.isNotEmpty) {
      await notificationService.sendTip(
        userId: userId,
        title: 'Conseil Babylonien',
        body: advice.first,
      );
    }

    // 5. Send notification for income distribution
    await notificationService.sendNotification(
      userId: userId,
      title: 'Revenu Réparti',
      body: 'Votre revenu de $amount FCFA a été automatiquement réparti dans vos coffres.',
      type: 'info',
    );

    // 6. Update general state
    await handleTransactionChanged(userId);
  }

  Future<void> handleTransactionChanged(int userId) async {
    // 1. Update financial score
    await babylonService.updateFinancialScore(userId);

    // 2. Track all goals
    final goals = await goalService.getGoals(userId: userId);
    for (var goal in goals) {
      await goalService.trackPerformance(goal['id']);
    }

    // 3. Update challenge progress
    await _updateChallengeProgress(userId);
  }

  Future<void> _updateChallengeProgress(int userId) async {
    final activeUserChallengesQuery = database.select(database.userChallenges)
      ..where((t) => t.userId.equals(userId) & t.status.equals('active'));
    final userChallengesList = await activeUserChallengesQuery.get();

    if (userChallengesList.isEmpty) return;

    // Calculate current net savings
    final incomesQuery = database.select(database.incomes)..where((t) => t.userId.equals(userId));
    final expensesQuery = database.select(database.expenses)..where((t) => t.userId.equals(userId));

    final incomes = await incomesQuery.get();
    final expenses = await expensesQuery.get();

    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final netSavings = totalIncome - totalExpense;

    for (var userChallenge in userChallengesList) {
      final challengeQuery = database.select(database.challenges)..where((t) => t.id.equals(userChallenge.challengeId));
      final challenge = await challengeQuery.getSingle();

      if (challenge.type == 'saving') {
        final progress = (netSavings / challenge.targetValue).clamp(0.0, 1.0);

        await (database.update(database.userChallenges)..where((t) => t.id.equals(userChallenge.id))).write(
          UserChallengesCompanion(
            progress: Value(progress),
            status: Value(progress >= 1.0 ? 'completed' : 'active'),
          ),
        );

        if (progress >= 1.0) {
          await babylonService.addPoints(userId, challenge.rewardPoints);
          await notificationService.sendCongratulation(
            userId: userId,
            title: 'Défi Relevé !',
            body: 'Vous avez terminé le défi : ${challenge.title} et gagné ${challenge.rewardPoints} points !',
          );
        }
      }
    }
  }

  Future<void> handleExpenseAdded(int? userId, String category, double amount) async {
    if (userId == null) return;

    // 1. Check budget
    final budgets = await budgetService.getBudgets(userId: userId);
    final categoryBudget = budgets.firstWhere(
      (b) => b['category'] == category,
      orElse: () => {},
    );

    if (categoryBudget.isNotEmpty) {
      final limit = categoryBudget['monthly_limit'] as double;

      // Calculate total spent for the category this month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final query = database.select(database.expenses)
        ..where((t) => t.userId.equals(userId) & t.category.equals(category) & t.createdAt.isBiggerOrEqualValue(startOfMonth));

      final expenses = await query.get();
      double totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

      if (totalSpent > limit) {
        await notificationService.sendAlert(
          userId: userId,
          title: 'Budget Dépassé',
          body: 'Attention ! Vous avez dépassé votre budget $category de ${totalSpent - limit} FCFA.',
        );
      } else if (totalSpent > limit * 0.9) {
        await notificationService.sendAlert(
          userId: userId,
          title: 'Alerte Budget',
          body: 'Vous avez utilisé plus de 90% de votre budget $category.',
        );
      }
    }

    // 2. Update general state
    await handleTransactionChanged(userId);

    // 3. Detect anomalies
    final anomalies = await analyticsService.detectFinancialAnomalies();
    if (anomalies.isNotEmpty) {
      await notificationService.sendAlert(
        userId: userId,
        title: 'Anomalie Détectée',
        body: anomalies.last,
      );
    }
  }
}

final automationServiceProvider = Provider<AutomationService>((ref) {
  final database = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final vaultService = ref.watch(vaultServiceProvider);
  final babylonService = ref.watch(babylonServiceProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final goalService = ref.watch(goalServiceProvider);
  final analyticsService = ref.watch(analyticsServiceProvider);

  return AutomationService(
    database: database,
    notificationService: notificationService,
    vaultService: vaultService,
    babylonService: babylonService,
    budgetService: budgetService,
    goalService: goalService,
    analyticsService: analyticsService,
  );
});

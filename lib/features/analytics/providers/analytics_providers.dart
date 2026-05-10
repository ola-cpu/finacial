import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_service.dart';
import '../../expenses/data/expense_service.dart';
import '../../incomes/data/income_service.dart';
import '../../budgets/data/budget_service.dart';
import '../../goals/data/goal_service.dart';

final analyticsServiceProvider = Provider((ref) {
  final expenseService = ref.watch(expenseServiceProvider);
  final incomeService = ref.watch(incomeServiceProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final goalService = ref.watch(goalServiceProvider);
  return AnalyticsService(expenseService, incomeService, budgetService, goalService);
});

final spendingHabitsProvider = FutureProvider((ref) {
  return ref.watch(analyticsServiceProvider).analyzeSpendingHabits();
});

final savingsProposalsProvider = FutureProvider((ref) {
  return ref.watch(analyticsServiceProvider).getSavingsProposals();
});

final excessiveSpendingProvider = FutureProvider((ref) {
  return ref.watch(analyticsServiceProvider).detectExcessiveSpending();
});

final suggestedBudgetsProvider = FutureProvider((ref) {
  return ref.watch(analyticsServiceProvider).suggestBudgets();
});

final futureBalanceProvider = FutureProvider((ref) {
  return ref.watch(analyticsServiceProvider).predictFutureBalance();
});

final babylonPrinciplesProvider = Provider((ref) {
  return ref.watch(analyticsServiceProvider).getBabylonPrinciples();
});

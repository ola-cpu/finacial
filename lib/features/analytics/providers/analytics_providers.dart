import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_service.dart';

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

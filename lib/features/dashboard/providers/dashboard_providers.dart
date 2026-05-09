import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../incomes/data/income_service.dart';
import '../../expenses/data/expense_service.dart';

final dashboardIncomesProvider = FutureProvider((ref) {
  return ref.watch(incomeServiceProvider).getIncomes();
});

final dashboardExpensesProvider = FutureProvider((ref) {
  return ref.watch(expenseServiceProvider).getExpenses();
});

final totalIncomeProvider = Provider((ref) {
  final incomes = ref.watch(dashboardIncomesProvider).value ?? [];
  return incomes.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
});

final totalExpenseProvider = Provider((ref) {
  final expenses = ref.watch(dashboardExpensesProvider).value ?? [];
  return expenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
});

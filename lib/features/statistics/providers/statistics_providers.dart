import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/data/expense_service.dart';
import '../../incomes/data/income_service.dart';
import '../../goals/data/goal_service.dart';

final categoryExpensesProvider = FutureProvider<Map<String, double>>((ref) async {
  final expenses = await ref.watch(expenseServiceProvider).getExpenses();
  final Map<String, double> categoryTotals = {};

  for (var expense in expenses) {
    final category = expense['category'] as String;
    final amount = (expense['amount'] as num).toDouble();
    categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
  }
  return categoryTotals;
});

final monthlyTrendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final expenses = await ref.watch(expenseServiceProvider).getExpenses();
  final incomes = await ref.watch(incomeServiceProvider).getIncomes();

  // Simple logic to group by month for the last 5 months
  final Map<String, Map<String, double>> monthlyData = {};

  void processItems(List<Map<String, dynamic>> items, String type) {
    for (var item in items) {
      final date = DateTime.parse(item['created_at']);
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      final amount = (item['amount'] as num).toDouble();

      monthlyData.putIfAbsent(monthKey, () => {'income': 0.0, 'expense': 0.0});
      monthlyData[monthKey]![type] = (monthlyData[monthKey]![type] ?? 0) + amount;
    }
  }

  processItems(incomes, 'income');
  processItems(expenses, 'expense');

  final sortedKeys = monthlyData.keys.toList()..sort();
  return sortedKeys.map((key) => {
    'month': key,
    'income': monthlyData[key]!['income'],
    'expense': monthlyData[key]!['expense'],
  }).toList();
});

final goalsProgressProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final goals = await ref.watch(goalServiceProvider).getGoals();
  final incomes = await ref.watch(incomeServiceProvider).getIncomes();
  final expenses = await ref.watch(expenseServiceProvider).getExpenses();

  final totalIncome = incomes.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  final totalExpense = expenses.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
  final savings = totalIncome - totalExpense;

  return goals.map((goal) {
    final target = (goal['target_amount'] as num).toDouble();
    // Simplified progress: current savings / target
    // In a real app, you might track savings specifically for goals
    final progress = (savings / target).clamp(0.0, 1.0);
    return {
      'title': goal['title'],
      'target': target,
      'progress': progress,
      'current': savings.clamp(0.0, target),
    };
  }).toList();
});

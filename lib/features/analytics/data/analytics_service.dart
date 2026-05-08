import '../../expenses/data/expense_service.dart';
import '../../incomes/data/income_service.dart';
import '../../budgets/data/budget_service.dart';

class AnalyticsService {
  final ExpenseService _expenseService;
  final IncomeService _incomeService;
  final BudgetService _budgetService;

  AnalyticsService(this._expenseService, this._incomeService, this._budgetService);

  Future<Map<String, double>> analyzeSpendingHabits() async {
    final expenses = await _expenseService.getExpenses();
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      final category = expense['category'] as String;
      final amount = (expense['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    return categoryTotals;
  }

  Future<List<String>> getSavingsProposals() async {
    final habits = await analyzeSpendingHabits();
    List<String> proposals = [];
    habits.forEach((category, amount) {
      if (amount > 50000) {
        proposals.add("Vous dépensez beaucoup en $category. Envisagez de réduire de 10% pour économiser ${amount * 0.1} FCFA.");
      }
    });
    if (proposals.isEmpty) {
      proposals.add("Vos dépenses sont bien maîtrisées. Continuez ainsi !");
    }
    return proposals;
  }

  Future<List<String>> detectExcessiveSpending() async {
    final expenses = await _expenseService.getExpenses();
    final budgets = await _budgetService.getBudgets();
    List<String> alerts = [];

    Map<String, double> categorySpending = {};
    for (var expense in expenses) {
      final category = expense['category'] as String;
      final amount = (expense['amount'] as num).toDouble();
      categorySpending[category] = (categorySpending[category] ?? 0) + amount;
    }

    for (var budget in budgets) {
      final category = budget['category'] as String;
      final limit = (budget['amount'] as num).toDouble();
      final spent = categorySpending[category] ?? 0;

      if (spent > limit) {
        alerts.add("ALERTE : Budget $category dépassé de ${spent - limit} FCFA !");
      } else if (spent > limit * 0.9) {
        alerts.add("Attention : Vous avez utilisé 90% de votre budget $category.");
      }
    }
    return alerts;
  }

  Future<List<Map<String, dynamic>>> suggestBudgets() async {
    final habits = await analyzeSpendingHabits();
    return habits.entries.map((e) {
      return {
        'category': e.key,
        'suggestedAmount': e.value * 0.9, // Suggest 10% less than average
      };
    }).toList();
  }

  Future<double> predictFutureBalance() async {
    final incomes = await _incomeService.getIncomes();
    final expenses = await _expenseService.getExpenses();

    double totalIncome = incomes.fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
    double totalExpense = expenses.fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());

    double currentBalance = totalIncome - totalExpense;

    // Simple prediction: assume next month spending/income will follow the monthly average
    // For this simple version, we assume the history is 1 month if not specified.
    // In a real app, we'd calculate the number of months between first and last transaction.

    double averageMonthlyIncome = totalIncome;
    double averageMonthlyExpense = totalExpense;

    return currentBalance + (averageMonthlyIncome - averageMonthlyExpense);
  }
}

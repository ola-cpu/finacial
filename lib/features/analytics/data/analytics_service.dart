import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../budgets/data/budget_service.dart';
import '../../goals/data/goal_service.dart';
import 'package:drift/drift.dart';

class AnalyticsService {
  final AppDatabase database;
  final BudgetService _budgetService;
  final GoalService? _goalService;

  AnalyticsService(this.database, this._budgetService, [this._goalService]);

  Future<List<Expense>> _getExpenses() async {
    return await database.select(database.expenses).get();
  }

  Future<List<Income>> _getIncomes() async {
    return await database.select(database.incomes).get();
  }

  Future<Map<String, double>> analyzeSpendingHabits() async {
    final expenses = await _getExpenses();
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      final category = expense.category;
      final amount = expense.amount;
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

    // Babylon inspired advice
    proposals.add("L'Homme le plus riche de Babylone dit : 'Une partie de tout ce que vous gagnez est à vous pour être gardée.'");
    proposals.add("Assurez-vous de mettre de côté au moins 10% de vos revenus avant toute dépense.");

    if (proposals.length <= 2) {
      proposals.add("Vos dépenses sont bien maîtrisées. Continuez ainsi !");
    }
    return proposals;
  }

  Future<List<String>> detectExcessiveSpending() async {
    final expenses = await _getExpenses();
    final budgets = await _budgetService.getBudgets();
    List<String> alerts = [];

    Map<String, double> categorySpending = {};
    for (var expense in expenses) {
      final category = expense.category;
      final amount = expense.amount;
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

    // Check emergency fund if goal service is available
    if (_goalService != null) {
      final goals = await _goalService!.getGoals();
      final emergencyGoal = goals.firstWhere(
        (g) => g['title'].toString().toLowerCase().contains('urgence'),
        orElse: () => {},
      );
      if (emergencyGoal.isNotEmpty && emergencyGoal['current_amount'] < emergencyGoal['target_amount'] * 0.5) {
        alerts.add("Conseil : Votre fonds d'urgence est encore faible. Donnez-lui la priorité.");
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
    final incomes = await _getIncomes();
    final expenses = await _getExpenses();

    double totalIncome = incomes.fold(0.0, (sum, item) => sum + item.amount);
    double totalExpense = expenses.fold(0.0, (sum, item) => sum + item.amount);

    double currentBalance = totalIncome - totalExpense;

    double monthlyBurnRate = totalExpense;
    double monthlyIncomeRate = totalIncome;

    return currentBalance + (monthlyIncomeRate - monthlyBurnRate);
  }

  Future<List<String>> generateAutomatedAdvice() async {
    final habits = await analyzeSpendingHabits();
    final incomes = await _getIncomes();
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    List<String> advice = [];

    if (totalIncome > 0) {
      habits.forEach((category, amount) {
        final percentage = (amount / totalIncome) * 100;
        if (percentage > 30) {
          advice.add("Votre catégorie $category représente ${percentage.toStringAsFixed(1)}% de vos revenus. L'Homme le plus riche de Babylone suggère de limiter les dépenses courantes pour maximiser l'épargne.");
        }
      });
    }

    if (habits.isEmpty) {
      advice.add("Commencez à enregistrer vos dépenses pour recevoir des conseils personnalisés.");
    }

    return advice;
  }

  Future<List<String>> detectFinancialAnomalies() async {
    final expenses = await _getExpenses();
    if (expenses.length < 5) return [];

    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final average = totalAmount / expenses.length;

    List<String> anomalies = [];
    for (var expense in expenses) {
      final amount = expense.amount;
      if (amount > average * 3) {
        anomalies.add("Dépense inhabituelle détectée : ${expense.title} ($amount FCFA) est nettement supérieure à votre moyenne.");
      }
    }

    return anomalies;
  }

  List<String> getBabylonPrinciples() {
    return [
      "Commencez par garnir votre bourse (Épargnez 1/10ème).",
      "Contrôlez vos dépenses.",
      "Faites fructifier votre or.",
      "Protégez votre trésor contre la perte.",
      "Faites de votre demeure un investissement profitable.",
      "Assurez un revenu pour l'avenir.",
      "Augmentez votre capacité d'acquérir des biens.",
    ];
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final database = ref.watch(databaseProvider);
  final budgetService = ref.watch(budgetServiceProvider);
  final goalService = ref.watch(goalServiceProvider);
  return AnalyticsService(database, budgetService, goalService);
});

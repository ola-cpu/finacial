import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class SyncService {
  final AppDatabase database;

  SyncService(this.database);

  Future<String> exportData() async {
    final expenses = await database.select(database.expenses).get();
    final incomes = await database.select(database.incomes).get();
    final budgets = await database.select(database.budgets).get();
    final goals = await database.select(database.goals).get();

    final data = {
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'incomes': incomes.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
    };

    return jsonEncode(data);
  }

  Future<void> importData(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    await database.transaction(() async {
      if (data.containsKey('expenses')) {
        for (var item in data['expenses']) {
          await database.into(database.expenses).insert(Expense.fromJson(item), mode: InsertMode.insertOrReplace);
        }
      }
      if (data.containsKey('incomes')) {
        for (var item in data['incomes']) {
          await database.into(database.incomes).insert(Income.fromJson(item), mode: InsertMode.insertOrReplace);
        }
      }
      if (data.containsKey('budgets')) {
        for (var item in data['budgets']) {
          await database.into(database.budgets).insert(Budget.fromJson(item), mode: InsertMode.insertOrReplace);
        }
      }
      if (data.containsKey('goals')) {
        for (var item in data['goals']) {
          await database.into(database.goals).insert(Goal.fromJson(item), mode: InsertMode.insertOrReplace);
        }
      }
    });
  }
}

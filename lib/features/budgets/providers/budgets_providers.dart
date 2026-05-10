import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/budget_service.dart';

final budgetsListProvider = FutureProvider((ref) {
  return ref.watch(budgetServiceProvider).getBudgets();
});

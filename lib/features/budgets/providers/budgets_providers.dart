import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/budget_service.dart';
import '../../auth/data/auth_service.dart';

final budgetsListProvider = FutureProvider((ref) {
  final user = ref.watch(currentUserProvider);
  return ref.watch(budgetServiceProvider).getBudgets(userId: user?.id);
});

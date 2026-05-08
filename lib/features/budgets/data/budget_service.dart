import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetService {
  final supabase = Supabase.instance.client;

  Future<void> addBudget({
    required String category,
    required double monthlyLimit,
  }) async {
    final user = supabase.auth.currentUser;

    await supabase.from('budgets').insert({
      'user_id': user!.id,
      'category': category,
      'monthly_limit': monthlyLimit,
    });
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    return await supabase
        .from('budgets')
        .select()
        .eq('user_id', user.id);
  }
}

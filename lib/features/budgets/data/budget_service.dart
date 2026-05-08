import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class BudgetService {
  final SupabaseClient supabase;

  BudgetService(this.supabase);

  Future<void> addBudget({
    required String category,
    required double monthlyLimit,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await supabase.from('budgets').insert({
      'user_id': user.id,
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

final budgetServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BudgetService(supabase);
});

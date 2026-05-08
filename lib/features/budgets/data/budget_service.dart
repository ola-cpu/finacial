import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class BudgetService {
  final SupabaseClient supabase;

  BudgetService(this.supabase);

  Future<void> addBudget({
    required String category,
    required double monthlyLimit,
  }) async {
    final user = supabase.auth.currentUser;

    // Offline first
    final box = Hive.box('budgets');
    await box.add({
      'category': category,
      'monthly_limit': monthlyLimit,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (user != null) {
      try {
        await supabase.from('budgets').insert({
          'user_id': user.id,
          'category': category,
          'monthly_limit': monthlyLimit,
        });
      } catch (e) {
        print('Supabase budget sync failed: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final box = Hive.box('budgets');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

final budgetServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return BudgetService(supabase);
});

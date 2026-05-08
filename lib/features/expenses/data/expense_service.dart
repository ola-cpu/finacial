import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class ExpenseService {
  final SupabaseClient supabase;

  ExpenseService(this.supabase);

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await supabase.from('expenses').insert({
      'user_id': user.id,
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    return await supabase
        .from('expenses')
        .select()
        .eq('user_id', user.id);
  }
}

final expenseServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ExpenseService(supabase);
});

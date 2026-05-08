import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class IncomeService {
  final SupabaseClient supabase;

  IncomeService(this.supabase);

  Future<void> addIncome({
    required String title,
    required double amount,
    required String category,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    await supabase.from('incomes').insert({
      'user_id': user.id,
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    return await supabase
        .from('incomes')
        .select()
        .eq('user_id', user.id);
  }
}

final incomeServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return IncomeService(supabase);
});

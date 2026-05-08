import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

    // Offline first: save to Hive
    final box = Hive.box('incomes');
    await box.add({
      'title': title,
      'amount': amount,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Try to sync with Supabase if online
    if (user != null) {
      try {
        await supabase.from('incomes').insert({
          'user_id': user.id,
          'title': title,
          'amount': amount,
          'category': category,
        });
      } catch (e) {
        // Sync failed, will be handled by a periodic sync task in a real app
        print('Supabase sync failed: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    // Return local data for offline support
    final box = Hive.box('incomes');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

final incomeServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return IncomeService(supabase);
});

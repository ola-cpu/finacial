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
    final now = DateTime.now().toIso8601String();

    String? remoteId;
    if (user != null) {
      try {
        final response = await supabase.from('incomes').insert({
          'user_id': user.id,
          'title': title,
          'amount': amount,
          'category': category,
        }).select('id').single();
        remoteId = response['id'].toString();
      } catch (e) {
        print('Supabase sync failed: $e');
      }
    }

    final box = Hive.box('incomes');
    await box.add({
      'remote_id': remoteId,
      'title': title,
      'amount': amount,
      'category': category,
      'created_at': now,
    });
  }

  Future<void> updateIncome({
    required dynamic key,
    required String title,
    required double amount,
    required String category,
  }) async {
    final user = supabase.auth.currentUser;
    final box = Hive.box('incomes');
    final income = Map<String, dynamic>.from(box.get(key));
    final remoteId = income['remote_id'];

    if (user != null && remoteId != null) {
      try {
        await supabase.from('incomes').update({
          'title': title,
          'amount': amount,
          'category': category,
        }).eq('id', remoteId);
      } catch (e) {
        print('Supabase update failed: $e');
      }
    }

    await box.put(key, {
      ...income,
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  Future<void> deleteIncome(dynamic key) async {
    final user = supabase.auth.currentUser;
    final box = Hive.box('incomes');
    final income = Map<String, dynamic>.from(box.get(key));
    final remoteId = income['remote_id'];

    if (user != null && remoteId != null) {
      try {
        await supabase.from('incomes').delete().eq('id', remoteId);
      } catch (e) {
        print('Supabase delete failed: $e');
      }
    }

    await box.delete(key);
  }

  Future<List<Map<String, dynamic>>> getIncomes() async {
    final box = Hive.box('incomes');
    return box.keys.map((key) {
      final value = box.get(key);
      return {
        'key': key,
        ...Map<String, dynamic>.from(value),
      };
    }).toList();
  }
}

final incomeServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return IncomeService(supabase);
});

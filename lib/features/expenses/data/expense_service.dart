import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    final now = DateTime.now().toIso8601String();

    String? remoteId;
    if (user != null) {
      try {
        final response = await supabase.from('expenses').insert({
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

    final box = Hive.box('expenses');
    await box.add({
      'remote_id': remoteId,
      'title': title,
      'amount': amount,
      'category': category,
      'created_at': now,
    });
  }

  Future<void> updateExpense({
    required int index,
    required String title,
    required double amount,
    required String category,
  }) async {
    final user = supabase.auth.currentUser;
    final box = Hive.box('expenses');
    final expense = box.getAt(index);
    final remoteId = expense['remote_id'];

    if (user != null && remoteId != null) {
      try {
        await supabase.from('expenses').update({
          'title': title,
          'amount': amount,
          'category': category,
        }).eq('id', remoteId);
      } catch (e) {
        print('Supabase update failed: $e');
      }
    }

    await box.putAt(index, {
      ...Map<String, dynamic>.from(expense),
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  Future<void> deleteExpense(int index) async {
    final user = supabase.auth.currentUser;
    final box = Hive.box('expenses');
    final expense = box.getAt(index);
    final remoteId = expense['remote_id'];

    if (user != null && remoteId != null) {
      try {
        await supabase.from('expenses').delete().eq('id', remoteId);
      } catch (e) {
        print('Supabase delete failed: $e');
      }
    }

    await box.deleteAt(index);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final box = Hive.box('expenses');
    return box.keys.map((key) {
      final value = box.get(key);
      return {
        'index': key,
        ...Map<String, dynamic>.from(value),
      };
    }).toList();
  }
}

final expenseServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return ExpenseService(supabase);
});

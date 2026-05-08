import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/providers/supabase_provider.dart';

class GoalService {
  final SupabaseClient supabase;

  GoalService(this.supabase);

  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final user = supabase.auth.currentUser;

    // Offline first
    final box = Hive.box('goals');
    await box.add({
      'title': title,
      'target_amount': targetAmount,
      'deadline': deadline.toIso8601String(),
      'saved_amount': 0.0,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (user != null) {
      try {
        await supabase.from('goals').insert({
          'user_id': user.id,
          'title': title,
          'target_amount': targetAmount,
          'deadline': deadline.toIso8601String(),
        });
      } catch (e) {
        print('Supabase goal sync failed: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    final box = Hive.box('goals');
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

final goalServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return GoalService(supabase);
});

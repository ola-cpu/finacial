import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (user == null) throw Exception("Not authenticated");

    await supabase.from('goals').insert({
      'user_id': user.id,
      'title': title,
      'target_amount': targetAmount,
      'deadline': deadline.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    return await supabase.from('goals').select().eq('user_id', user.id);
  }
}

final goalServiceProvider = Provider((ref) {
  final supabase = ref.watch(supabaseProvider);
  return GoalService(supabase);
});

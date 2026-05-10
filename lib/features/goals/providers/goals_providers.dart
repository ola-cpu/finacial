import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/goal_service.dart';

final goalsListProvider = FutureProvider((ref) {
  return ref.watch(goalServiceProvider).getGoals();
});

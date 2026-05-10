import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/database/app_database.dart';

class AdviceService {
  final AppDatabase database;

  AdviceService(this.database);

  /// CREATE: Adds a new financial advice for a specific user.
  Future<void> createAdvice({
    required int? userId,
    required String title,
    required String content,
    required String type,
  }) async {
    await database.into(database.advices).insert(
          AdvicesCompanion.insert(
            userId: Value(userId),
            title: title,
            content: content,
            type: type,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// READ: Retrieves all non-archived advices for a specific user.
  Future<List<Advice>> getAdvices(int? userId) async {
    final query = database.select(database.advices);
    query.where((t) {
      final conditions = [t.isArchived.equals(false)];
      if (userId != null) {
        conditions.add(t.userId.equals(userId));
      }
      return Expression.and(conditions);
    });
    return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// READ: Retrieves all advices (including archived) for a specific user.
  Future<List<Advice>> getAdviceHistory(int? userId) async {
    final query = database.select(database.advices);
    if (userId != null) {
      query.where((t) => t.userId.equals(userId));
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// UPDATE: Updates an existing advice's title, content, or type.
  Future<void> updateAdvice({
    required int id,
    String? title,
    String? content,
    String? type,
  }) async {
    await (database.update(database.advices)..where((t) => t.id.equals(id))).write(
      AdvicesCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        content: content != null ? Value(content) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
      ),
    );
  }

  /// UPDATE: Archives an advice instead of deleting it.
  Future<void> archiveAdvice(int id) async {
    await (database.update(database.advices)..where((t) => t.id.equals(id))).write(
      const AdvicesCompanion(isArchived: Value(true)),
    );
  }

  /// DELETE: Permanently removes an advice from the database.
  Future<void> deleteAdvice(int id) async {
    await (database.delete(database.advices)..where((t) => t.id.equals(id))).go();
  }
}

final adviceServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return AdviceService(database);
});

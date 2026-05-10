import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';

class NotificationService {
  final AppDatabase database;

  NotificationService(this.database);

  Future<void> sendNotification({
    required int? userId,
    required String title,
    required String body,
    required String type,
  }) async {
    await database.into(database.notifications).insert(
          NotificationsCompanion.insert(
            userId: Value(userId),
            title: title,
            body: body,
            type: type,
            createdAt: DateTime.now(),
          ),
        );

    // In a real app, integrate with flutter_local_notifications here
    debugPrint('NOTIFICATION: $title - $body');
  }

  Future<List<Notification>> getNotifications(int? userId) async {
    final select = database.select(database.notifications);
    if (userId != null) {
      select.where((t) => t.userId.equals(userId));
    }
    return (select..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<void> markAsRead(int id) async {
    await (database.update(database.notifications)..where((t) => t.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }
}

final notificationServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return NotificationService(database);
});

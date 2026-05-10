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

  Future<void> sendAlert({
    required int? userId,
    required String title,
    required String body,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'alert',
    );
  }

  Future<void> sendCongratulation({
    required int? userId,
    required String title,
    required String body,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'congratulation',
    );
  }

  Future<void> sendTip({
    required int? userId,
    required String title,
    required String body,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'tip',
    );
  }

  Future<List<Notification>> getNotifications(int? userId) async {
    final select = database.select(database.notifications);
    if (userId != null) {
      select.where((t) => t.userId.equals(userId));
    }
    return (select..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// UPDATE: Marks a notification as read.
  Future<void> markAsRead(int id) async {
    await (database.update(database.notifications)..where((t) => t.id.equals(id))).write(
      const NotificationsCompanion(isRead: Value(true)),
    );
  }

  /// UPDATE: Modifies an existing notification's content or type.
  Future<void> updateNotification({
    required int id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
  }) async {
    await (database.update(database.notifications)..where((t) => t.id.equals(id))).write(
      NotificationsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        body: body != null ? Value(body) : const Value.absent(),
        type: type != null ? Value(type) : const Value.absent(),
        isRead: isRead != null ? Value(isRead) : const Value.absent(),
      ),
    );
  }

  /// DELETE: Removes a notification from the database.
  Future<void> deleteNotification(int id) async {
    await (database.delete(database.notifications)..where((t) => t.id.equals(id))).go();
  }
}

final notificationServiceProvider = Provider((ref) {
  final database = ref.watch(databaseProvider);
  return NotificationService(database);
});

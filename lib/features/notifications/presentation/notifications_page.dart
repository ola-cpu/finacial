import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/database/app_database.dart' as db;

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notificationService = ref.watch(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<db.Notification>>(
        future: notificationService.getNotifications(user?.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune notification'));
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.isRead ? Colors.grey : const Color(0xFF50C878),
                  child: Icon(
                    notification.type == 'ALERTE' ? Icons.warning : Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(notification.body),
                onTap: () async {
                  await notificationService.markAsRead(notification.id);
                  // Refresh UI
                  (context as Element).markNeedsBuild();
                },
              );
            },
          );
        },
      ),
    );
  }
}

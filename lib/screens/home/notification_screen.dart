import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/service/notification_service.dart';
import '../../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = NotificationService.getNotifications();
    // Cài đặt ngôn ngữ cho timeago để hiển thị "phút trước", "giờ trước"...
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return Icons.assignment_turned_in_outlined;
      case NotificationType.reportApproved:
        return Icons.check_circle_outline;
      case NotificationType.reportNeedsUpdate:
        return Icons.error_outline;
      case NotificationType.general:
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return Colors.blue.shade700;
      case NotificationType.reportApproved:
        return Colors.green.shade700;
      case NotificationType.reportNeedsUpdate:
        return Colors.red.shade700;
      case NotificationType.general:
      default:
        return Colors.grey.shade700;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // TODO: Triển khai điều hướng dựa trên loại thông báo và entityId
    // Ví dụ:
    // if (notification.type == NotificationType.taskAssigned && notification.entityId != null) {
    //   Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: notification.entityId!)));
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã nhấn vào thông báo: ${notification.title}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF6F8F7),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải thông báo: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Bạn chưa có thông báo nào',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final color = _getColorForType(notification.type);

              return Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => _handleNotificationTap(notification),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child:
                        Icon(_getIconForType(notification.type), color: color),
                  ),
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(notification.body),
                  trailing: Text(
                    timeago.format(notification.createdAt, locale: 'vi'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Bắn thông báo ra ngoài màn hình điện thoại thật
          NotificationService.showImmediateNotification(
            id: DateTime.now().millisecond,
            title: 'Nhiệm vụ mới!',
            body: 'Quản lý vừa giao cho bạn một công việc cần xử lý gấp.',
          );
        },
        icon: const Icon(Icons.notification_add),
        label: const Text('Test Thông báo'),
      ),
    );
  }
}

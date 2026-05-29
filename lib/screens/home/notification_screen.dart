import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/service/notification_service.dart';
import '../../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  // Hàm hiển thị Popup Thông báo trượt từ phải sang
  static void showRightPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotificationPanel',
      barrierColor: Colors.black.withOpacity(0.5), // Nền tối phía sau
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Giới hạn chiều rộng trên Tablet, hoặc chiếm 85% màn hình trên Mobile
              maxWidth: MediaQuery.of(context).size.width * 0.85 > 400
                  ? 400
                  : MediaQuery.of(context).size.width * 0.85,
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: const ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: NotificationScreen(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Hiệu ứng trượt từ phải (1.0) qua trái (0.0)
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        // Hiệu ứng mờ dần (Fade In)
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        NotificationService.getNotifications(),
        NotificationService.getUnreadCount(),
      ]);
      if (mounted) {
        setState(() {
          _notifications = results[0] as List<NotificationModel>;
          _unreadCount = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Lỗi tải thông báo: $e');
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return Icons.assignment_turned_in_outlined;
      case NotificationType.reportApproved:
        return Icons.check_circle_outline;
      case NotificationType.reportNeedsUpdate:
        return Icons.error_outline;
      case NotificationType.sensorAlert:
        return Icons.warning_amber_rounded;
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
      case NotificationType.sensorAlert:
        return Colors.orange.shade700;
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

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;
    final success = await NotificationService.markAllAsRead();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả là đã đọc'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
            _unreadCount > 0 ? 'Thông báo ($_unreadCount)' : 'Thông báo',
            style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc tất cả',
                  style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            )
        ],
      ),
      backgroundColor: const Color(0xFFF6F8F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _notifications.isEmpty
              ? const Center(
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
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: Colors.teal,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final color = _getColorForType(notification.type);
                      final isUnread = !notification.isRead;

                      return Card(
                        elevation: isUnread ? 2 : 0.5,
                        color: isUnread ? Colors.teal.shade50 : Colors.white,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: isUnread
                                  ? Colors.teal.shade200
                                  : Colors.transparent,
                              width: 1),
                        ),
                        child: ListTile(
                          onTap: () => _handleNotificationTap(notification),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(_getIconForType(notification.type),
                                color: color),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color:
                                    isUnread ? Colors.black87 : Colors.black54),
                          ),
                          subtitle: Text(
                            notification.body,
                            style: TextStyle(
                                color:
                                    isUnread ? Colors.black87 : Colors.black54),
                          ),
                          trailing: Text(
                            timeago.format(notification.createdAt.toLocal(),
                                locale: 'vi'),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

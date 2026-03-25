import 'package:flutter/material.dart';
import '../../core/service/notifiactionservice.dart';
import '../task/task_detail_screen.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color bgColor = Color(0xFFF6F8F7);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<_NotificationData> notifications = [];

  int _notifIdCounter = 100;
  static Future<void> triggerNewTaskNotification({
    required String taskTitle,
    required String assignedBy,
    String? taskId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;

    await NotificationService.showNewTaskNotification(
      id: id,
      taskTitle: taskTitle,
      assignedBy: assignedBy,
      taskId: taskId,
    );
  }

  void _handleTap(_NotificationData item) {
    setState(() => item.unread = false);

    switch (item.type) {
      case 'task':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: item.referenceId),
          ),
        );
        break;
      case 'report':
        Navigator.pushNamed(context, '/reportDetail',
            arguments: item.referenceId);
        break;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.unread = false;
      }
    });
  }

  // ─── Thêm notification mới vào danh sách trong app ───────────────────────
  void _addToInAppList(String title, String description) {
    setState(() {
      notifications.insert(
        0,
        _NotificationData(
          icon: Icons.task_alt,
          iconBg: const Color(0xFFF3E5F5),
          iconColor: Colors.deepPurple,
          title: title,
          description: description,
          time: 'Vừa xong',
          type: 'task',
          referenceId: 'task_$_notifIdCounter',
          unread: true,
        ),
      );
      _notifIdCounter++;
    });
  }

  // ─── Nút test thủ công ────────────────────────────────────────────────────
  Future<void> _sendTestNotification() async {
    const taskTitle = 'Kiểm tra sâu bệnh khu vực B';
    const assignedBy = 'Owner Nguyễn Văn A';
    const taskId = 'task_999';

    // 1. Bắn local notification lên system tray
    await triggerNewTaskNotification(
      taskTitle: taskTitle,
      assignedBy: assignedBy,
      taskId: taskId,
    );

    // 2. Thêm vào danh sách in-app
    _addToInAppList(
      'Nhiệm vụ mới: $taskTitle',
      '$assignedBy vừa phân công cho bạn.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi notification thử nghiệm'),
          backgroundColor: primaryTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Đánh dấu đã đọc',
              style: TextStyle(
                color: primaryTeal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // ── Banner test notification ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryTeal.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active,
                    color: primaryTeal, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Trigger thủ công khi owner giao task',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: _sendTestNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Gửi thử',
                      style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Danh sách notification ───────────────────────────────────────
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('Không có thông báo nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return GestureDetector(
                        onTap: () => _handleTap(item),
                        child: _NotificationItem(
                          icon: item.icon,
                          iconBg: item.iconBg,
                          iconColor: item.iconColor,
                          title: item.title,
                          description: item.description,
                          time: item.time,
                          unread: item.unread,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String time;
  final String type;
  final String referenceId;
  bool unread;

  _NotificationData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    required this.referenceId,
    this.unread = false,
  });
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String time;
  final bool unread;

  const _NotificationItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
    this.unread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFEFFFFE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: primaryTeal,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(time,
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

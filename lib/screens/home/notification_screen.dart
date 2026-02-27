import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color bgColor = Color(0xFFF6F8F7);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<_NotificationData> notifications = [
    _NotificationData(
      icon: Icons.bug_report,
      iconBg: const Color(0xFFFFEDED),
      iconColor: Colors.red,
      title: 'Phát hiện rầy nâu tại Khu A',
      description: 'AI nhận diện mật độ cao, cần kiểm tra ngay lập tức.',
      time: '5 phút trước',
      type: 'report',
      referenceId: 'report_1',
      unread: true,
    ),
    _NotificationData(
      icon: Icons.task_alt,
      iconBg: const Color(0xFFF3E5F5),
      iconColor: Colors.deepPurple,
      title: 'Nhiệm vụ mới được phân công',
      description: 'Bạn được phân công kiểm tra khu vực D.',
      time: '5 giờ trước',
      type: 'task',
      referenceId: 'task_1',
      unread: true,
    ),
  ];

  void _handleTap(_NotificationData item) {
    setState(() {
      item.unread = false;
    });

    switch (item.type) {
      case 'task':
        Navigator.pushNamed(
          context,
          '/taskDetail',
          arguments: item.referenceId,
        );
        break;

      case 'report':
        Navigator.pushNamed(
          context,
          '/reportDetail',
          arguments: item.referenceId,
        );
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
      body: ListView.builder(
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
  final String type; // task | report
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
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
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
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

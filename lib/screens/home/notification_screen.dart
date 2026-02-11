import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color bgColor = Color(0xFFF6F8F7);

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static final List<_NotificationData> notifications = [
    _NotificationData(
      icon: Icons.bug_report,
      iconBg: Color(0xFFFFEDED),
      iconColor: Colors.red,
      title: 'Phát hiện rầy nâu tại Khu A',
      description:
          'AI nhận diện mật độ cao, cần kiểm tra ngay lập tức để tránh lây lan.',
      time: '5 phút trước',
      unread: true,
    ),
    _NotificationData(
      icon: Icons.warning_amber_rounded,
      iconBg: Color(0xFFFFF3E0),
      iconColor: Colors.orange,
      title: 'Nghi ngờ bệnh đạo ôn lá',
      description: 'Scan hình ảnh lá lúa tại Khu C cho thấy dấu hiệu sớm.',
      time: '20 phút trước',
      unread: true,
    ),
    _NotificationData(
      icon: Icons.water_drop,
      iconBg: Color(0xFFE0F7FA),
      iconColor: primaryTeal,
      title: 'Nhiệm vụ "Tưới nước" sắp hết hạn',
      description: 'Khu vực B chưa hoàn thành tưới tiêu theo lịch trình.',
      time: '30 phút trước',
    ),
    _NotificationData(
      icon: Icons.cloud,
      iconBg: Color(0xFFE3F2FD),
      iconColor: Colors.blue,
      title: 'Cảnh báo mưa lớn chiều nay',
      description: 'Dự báo lượng mưa 50mm, hãy che chắn khu vật tư.',
      time: '1 giờ trước',
    ),
    _NotificationData(
      icon: Icons.check_circle,
      iconBg: Color(0xFFE8F5E9),
      iconColor: Colors.green,
      title: 'Chuyên gia đã nhận xét báo cáo',
      description: 'Bệnh đạo ôn cần xử lý thuốc X theo liều lượng.',
      time: '3 giờ trước',
    ),
    _NotificationData(
      icon: Icons.task_alt,
      iconBg: Color(0xFFF3E5F5),
      iconColor: Colors.deepPurple,
      title: 'Nhiệm vụ mới được phân công',
      description: 'Bạn được phân công kiểm tra khu vực D vào sáng mai.',
      time: '5 giờ trước',
    ),
    _NotificationData(
      icon: Icons.update,
      iconBg: Color(0xFFE1F5FE),
      iconColor: Colors.lightBlue,
      title: 'Cập nhật lịch chăm sóc',
      description: 'Lịch bón phân khu A đã được điều chỉnh.',
      time: 'Hôm qua',
    ),
  ];

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Đánh dấu đã đọc',
                style: TextStyle(
                  color: primaryTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
          return _NotificationItem(
            icon: item.icon,
            iconBg: item.iconBg,
            iconColor: item.iconColor,
            title: item.title,
            description: item.description,
            time: item.time,
            unread: item.unread,
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
  final bool unread;

  _NotificationData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.time,
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
        color: Colors.white,
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

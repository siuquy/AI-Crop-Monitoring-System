import 'package:flutter/foundation.dart';

import '../../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final apiClient = ApiClient.instance;
      // TODO: Thay thế bằng endpoint API thật khi có, ví dụ: '/api/notifications'
      // final response = await apiClient.get('/api/notifications');

      // if (response != null && response['success'] == true && response['data'] is List) {
      //   final List<dynamic> notificationData = response['data'];
      //   return notificationData.map((json) => NotificationModel.fromJson(json)).toList();
      // } else {
      //   throw ApiException(response?['message'] ?? 'Không tải được thông báo.');
      // }

      // Sử dụng dữ liệu giả vì chưa có API
      await Future.delayed(const Duration(seconds: 1)); // Giả lập độ trễ mạng
      return _getMockNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi tải thông báo: $e. Trả về dữ liệu giả.');
      }
      // Trả về dữ liệu giả nếu có lỗi để ứng dụng không bị crash
      return _getMockNotifications();
    }
  }

  // Dữ liệu giả để minh họa
  static List<NotificationModel> _getMockNotifications() {
    return [
      NotificationModel(
        id: '1',
        title: 'Công việc mới được giao',
        body: 'Bạn có một công việc mới: "Tưới nước cho ruộng cà chua A".',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.taskAssigned,
        entityId: 'task_123',
      ),
      NotificationModel(
        id: '2',
        title: 'Báo cáo đã được duyệt',
        body:
            'Báo cáo "Sâu bệnh hại lúa" của bạn đã được chuyên gia phê duyệt.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.reportApproved,
        isRead: true,
        entityId: 'report_1',
      ),
      NotificationModel(
        id: '3',
        title: 'Yêu cầu bổ sung báo cáo',
        body:
            'Báo cáo "Tình trạng cây ngô" cần bổ sung thêm hình ảnh rõ nét hơn.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.reportNeedsUpdate,
        entityId: 'report_3',
      ),
    ];
  }
}

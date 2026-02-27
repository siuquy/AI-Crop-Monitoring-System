import '../models/app_notification.dart';

class MockNotification {
  static List<AppNotification> notifications = [
    AppNotification(
      id: '1',
      title: 'Task mới được giao',
      body: 'Bạn vừa được giao nhiệm vụ kiểm tra máy A',
      type: 'task',
      referenceId: 'task_1',
      createdAt: DateTime.now(),
    ),
    AppNotification(
      id: '2',
      title: 'Báo cáo đã được cập nhật',
      body: 'Báo cáo số 23 đã được phê duyệt',
      type: 'report',
      referenceId: 'report_1',
      createdAt: DateTime.now(),
    ),
  ];
}

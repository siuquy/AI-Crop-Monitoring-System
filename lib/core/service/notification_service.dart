import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:acmms/models/task_model.dart';
import '../../models/notification.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        selectNotificationStream.add(response.payload);
      },
    );

    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> scheduleTaskNotification(TaskModel task) async {
    if (task.startDate == null) return;

    final scheduledTime = task.startDate!.subtract(const Duration(minutes: 15));
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      task.id.hashCode,
      'Sắp đến giờ làm việc!',
      'Công việc "${task.title}" sẽ bắt đầu lúc ${task.startDate!.hour}:${task.startDate!.minute.toString().padLeft(2, '0')}.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminder_channel',
          'Nhắc nhở công việc',
          channelDescription: 'Thông báo nhắc nhở khi sắp đến giờ làm việc',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_notification_channel',
      'Thông báo tức thời',
      channelDescription: 'Kênh cho các thông báo hiển thị ngay lập tức',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
        android: androidDetails, iOS: DarwinNotificationDetails());

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  static Future<List<NotificationModel>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return _getMockNotifications();
  }

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

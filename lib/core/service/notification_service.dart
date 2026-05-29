import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:acmms/models/task_model.dart';
import '../../models/notification.dart';
import 'api_client.dart';

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

  static Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiClient.instance.get(
          '/api/Notifications?unreadOnly=$unreadOnly&page=$page&pageSize=$pageSize');
      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        final data = response['data'] as List<dynamic>;
        return data
            .map((json) =>
                NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final response =
          await ApiClient.instance.get('/api/Notifications/unread-count');
      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        return int.tryParse(response['data'].toString()) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> markAllAsRead() async {
    try {
      final response =
          await ApiClient.instance.put('/api/Notifications/read-all');
      return response != null && response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

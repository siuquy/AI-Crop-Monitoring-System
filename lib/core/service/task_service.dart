import 'package:acmms/models/task_model.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';

class TaskService {
  static Future<List<dynamic>> getAllTasks() async {
    try {
      final response = await ApiClient.instance.get('/api/Tasks');
      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        return response['data'];
      }
      return [];
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách Công việc (Tasks): $e');
    }
  }

  static Future<List<TaskModel>> getTasks({bool forceRefresh = false}) async {
    return getTaskList();
  }

  static Future<List<TaskModel>> getTaskList() async {
    try {
      final response =
          await ApiClient.instance.get('/api/WorkerSchedules/my-schedule');
      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        final List<dynamic> schedules = response['data'];

        return schedules.map<TaskModel>((item) {
          return TaskModel(
            id: item['taskDetailId'] ?? item['scheduleId'] ?? '',
            title: item['taskTitle'] ?? 'Không có tiêu đề',
            description: 'Lịch làm việc cho: ${item['workerName'] ?? 'Bạn'}',
            status: _mapStatus(item['status'] ?? item['taskDetailStatus']),
            seasonId: '',
            bedIds: <String>[],
            bed: '',
            taskType: 'Chăm sóc',
            isUrgent: item['status']?.toString().toLowerCase() == 'urgent' ||
                item['taskDetailStatus']?.toString().toLowerCase() == 'urgent',
            imageAsset: 'assets/monitoring.jpg',
            assignedBy: 'Quản lý',
            assignedRole: 'Admin',
            avatarIcon: Icons.task_alt,
            startDate: item['startDate'] != null
                ? DateTime.parse(item['startDate']).toLocal()
                : DateTime.now(),
            endDate: item['endDate'] != null
                ? DateTime.parse(item['endDate']).toLocal()
                : null,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách lịch làm việc: $e');
    }
  }

  static Future<TaskModel> getTaskById(String taskId) async {
    try {
      final tasks = await getTaskList();
      final task = tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () =>
            throw ApiException('Không tìm thấy công việc với ID: $taskId'),
      );
      return task;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lỗi khi tải chi tiết công việc: $e');
    }
  }

  static Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await Future.delayed(
          const Duration(seconds: 1)); 
    } catch (e) {
      throw ApiException('Lỗi khi cập nhật trạng thái: $e');
    }
  }

  static TaskStatus _mapStatus(String? statusStr) {
    if (statusStr == null) return TaskStatus.pending;
    final s = statusStr.toLowerCase();
    if (s.contains('active') || s.contains('doing') || s.contains('progress'))
      return TaskStatus.doing;
    if (s.contains('completed') || s.contains('done'))
      return TaskStatus.completed;
    if (s.contains('urgent')) return TaskStatus.urgent;
    return TaskStatus.pending;
  }
}

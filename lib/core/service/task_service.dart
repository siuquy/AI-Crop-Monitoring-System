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

  static Future<List<dynamic>> getAllTaskDetails() async {
    try {
      final response = await ApiClient.instance.get('/api/TaskDetails');
      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        return response['data'];
      }
      return [];
    } catch (e) {
      throw ApiException(
          'Lỗi khi tải danh sách Chi tiết công việc (TaskDetails): $e');
    }
  }

  static Future<List<TaskModel>> getTasks({bool forceRefresh = false}) async {
    return getTaskList();
  }

  static Future<List<TaskModel>> getTaskList() async {
    try {
      final results = await Future.wait([
        getAllTasks(),
        getAllTaskDetails(),
      ]);

      final tasks = results[0] as List<dynamic>;
      final taskDetails = results[1] as List<dynamic>;

      return tasks.map<TaskModel>((task) {
        final detail = taskDetails.firstWhere(
            (d) => d['taskId'] == task['taskId'],
            orElse: () => null);

        final bedIds = detail != null && detail['bedIds'] != null
            ? List<String>.from(detail['bedIds'])
            : <String>[];
        final firstBedId = bedIds.isNotEmpty ? bedIds.first : '';

        return TaskModel(
          id: task['taskId'] ?? '',
          title:
              task['taskTitle'] ?? detail?['taskTitle'] ?? 'Không có tiêu đề',
          description: task['taskNotes'] ?? detail?['notes'] ?? '',
          status: _mapStatus(task['taskStatus']),
          seasonId: detail?['seasonId'] ?? '',
          bedIds: bedIds,
          bed: firstBedId,
          taskType: 'Chăm sóc',
          isUrgent: task['taskStatus']?.toString().toLowerCase() == 'urgent',
          imageAsset: 'assets/monitoring.jpg',
          assignedBy: 'Quản lý',
          assignedRole: 'Admin',
          avatarIcon: Icons.task_alt,
          startDate: detail?['startDate'] != null
              ? DateTime.parse(detail['startDate'])
              : DateTime.now(),
          endDate: detail?['endDate'] != null
              ? DateTime.parse(detail['endDate'])
              : null,
        );
      }).toList();
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách công việc: $e');
    }
  }

  static Future<TaskModel> getTaskById(String taskId) async {
    try {
      final results = await Future.wait([
        getAllTasks(),
        getAllTaskDetails(),
      ]);

      final tasks = results[0];
      final taskDetails = results[1];

      final task =
          tasks.firstWhere((t) => t['taskId'] == taskId, orElse: () => null);
      if (task == null) {
        throw ApiException('Không tìm thấy công việc với ID: $taskId');
      }

      final detail = taskDetails.firstWhere((d) => d['taskId'] == taskId,
          orElse: () => null);

      final bedIds = detail != null && detail['bedIds'] != null
          ? List<String>.from(detail['bedIds'])
          : <String>[];
      final firstBedId = bedIds.isNotEmpty ? bedIds.first : '';

      return TaskModel(
        id: task['taskId'] ?? '',
        title: task['taskTitle'] ?? detail?['taskTitle'] ?? 'Không có tiêu đề',
        description: task['taskNotes'] ?? detail?['notes'] ?? '',
        status: _mapStatus(task['taskStatus']),
        seasonId: detail?['seasonId'] ?? '',
        bedIds: bedIds,
        bed: firstBedId,
        taskType: 'Chăm sóc',
        isUrgent: task['taskStatus']?.toString().toLowerCase() == 'urgent',
        imageAsset: 'assets/monitoring.jpg',
        assignedBy: 'Quản lý',
        assignedRole: 'Admin',
        avatarIcon: Icons.task_alt,
        startDate: detail?['startDate'] != null
            ? DateTime.parse(detail['startDate'])
            : DateTime.now(),
        endDate: detail?['endDate'] != null
            ? DateTime.parse(detail['endDate'])
            : null,
      );
    } catch (e) {
      throw ApiException('Lỗi khi tải chi tiết công việc: $e');
    }
  }

  static TaskStatus _mapStatus(String? statusStr) {
    if (statusStr == null) return TaskStatus.pending;
    final s = statusStr.toLowerCase();
    if (s.contains('active') || s.contains('doing')) return TaskStatus.doing;
    if (s.contains('completed')) return TaskStatus.completed;
    if (s.contains('urgent')) return TaskStatus.urgent;
    return TaskStatus.pending;
  }
}

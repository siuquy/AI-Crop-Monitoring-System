import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/task_model.dart';
import 'api_client.dart';

class TaskService {
  TaskService._();

  static List<TaskModel>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(seconds: 60);

  static void clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[TaskService] $message');
    }
  }

  static Future<List<TaskModel>> getTasks({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Returning cached tasks (${_cache!.length})');
      return _cache!;
    }

    _log('Fetching fresh tasks from API');
    final result = await _getTaskList('/api/Tasks');

    _cache = result;
    _cacheTime = DateTime.now();
    return result;
  }

  /// Fetches a single task by its ID.
  /// NOTE: This has been simplified. The previous implementation was very inefficient,
  /// fetching all task details for every single task lookup.
  /// The backend API `/api/Tasks/{id}` should ideally return all necessary information.
  static Future<TaskModel> getTaskById(String id) async {
    try {
      final dynamic taskJson = await ApiClient.instance.get('/api/Tasks/$id');

      if (taskJson is Map<String, dynamic>) {
        // The API response might be wrapped in a 'data' object.
        Map<String, dynamic> taskData = taskJson.containsKey('data') &&
                taskJson['data'] is Map<String, dynamic>
            ? taskJson['data']
            : taskJson;

        return TaskModel.fromJson(taskData);
      }

      throw ApiException('Dữ liệu task không hợp lệ');
    } catch (e) {
      _log('Error fetching task by ID $id: $e');
      rethrow;
    }
  }

  static Future<List<TaskModel>> _getTaskList(String path) async {
    try {
      final dynamic taskDataJson = await ApiClient.instance.get(path);

      List<Map<String, dynamic>> taskListJson;

      if (taskDataJson is List) {
        taskListJson = taskDataJson.whereType<Map<String, dynamic>>().toList();
      } else if (taskDataJson is Map<String, dynamic> &&
          taskDataJson.containsKey('data') &&
          taskDataJson['data'] is List) {
        taskListJson =
            (taskDataJson['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw ApiException('Dữ liệu danh sách task không hợp lệ');
      }

      return taskListJson.map(TaskModel.fromJson).toList();
    } catch (e) {
      _log('Error fetching task list: $e');
      rethrow;
    }
  }
}

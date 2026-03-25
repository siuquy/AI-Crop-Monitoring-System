import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/task_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

class TaskService {
  TaskService._();

  static const String _baseUrl = 'https://10.0.2.2:7093';
  static const Duration _timeout = Duration(seconds: 8);

  static List<TaskModel>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(seconds: 60);

  static void clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  static Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[TaskService] $message');
    }
  }

  static Future<http.Response> _get(Uri uri) async {
    _log('GET $uri');
    var response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        final newUri = uri.resolve(location);
        _log('Following temporary redirect to $newUri');
        response = await http.get(newUri,
            headers: const {'Accept': 'application/json'}).timeout(_timeout);
      }
    }
    return response;
  }

  static Future<List<TaskModel>> getTasks({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Returning cached tasks (${_cache!.length})');
      return _cache!;
    }

    final uri = _buildUri('/api/Tasks');
    final result = await _getTaskList(uri);

    _cache = result;
    _cacheTime = DateTime.now();
    return result;
  }

  static Future<TaskModel> getTaskById(String id) async {
    final taskUri = _buildUri('/api/Tasks/$id');
    final detailsUri = _buildUri('/api/TaskDetails');

    try {
      final responses = await Future.wait([
        _get(taskUri),
        _get(detailsUri),
      ]);

      final taskResponse = responses[0];
      final detailsResponse = responses[1];

      _log('Task Status: ${taskResponse.statusCode}');
      _log('Details Status: ${detailsResponse.statusCode}');

      _ensureSuccess(taskResponse);
      _ensureSuccess(detailsResponse);

      final dynamic taskJson = _decodeJson(taskResponse.body);
      final dynamic detailsJson = _decodeJson(detailsResponse.body);

      if (taskJson is Map<String, dynamic>) {
        Map<String, dynamic> taskData = taskJson.containsKey('data') &&
                taskJson['data'] is Map<String, dynamic>
            ? taskJson['data']
            : taskJson;

        if (detailsJson is Map<String, dynamic> &&
            detailsJson.containsKey('data') &&
            detailsJson['data'] is List) {
          final detailsList = detailsJson['data'] as List;
          final detailData = detailsList.firstWhere((d) => d['taskId'] == id,
              orElse: () => null);

          if (detailData != null) {
            if (detailData.containsKey('notes')) {
              detailData['taskNotes'] = detailData['notes'];
            }
            taskData.addAll(detailData);
          }
        }
        return TaskModel.fromJson(taskData);
      }

      throw ApiException('Dữ liệu task không hợp lệ');
    } on SocketException {
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra backend có đang chạy không.');
    } on TimeoutException {
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } on FormatException {
      throw ApiException('Phản hồi từ server không đúng định dạng JSON.');
    }
  }

  static Future<List<TaskModel>> _getTaskList(Uri uri) async {
    try {
      final response = await _get(uri);

      _log('Status: ${response.statusCode}');

      _ensureSuccess(response);

      final dynamic taskDataJson = _decodeJson(response.body);
      List<Map<String, dynamic>> taskListJson;

      if (taskDataJson is List) {
        taskListJson = taskDataJson.whereType<Map<String, dynamic>>().toList();
      } else if (taskDataJson is Map<String, dynamic> &&
          taskDataJson.containsKey('data') &&
          taskDataJson['data'] is List) {
        taskListJson = (taskDataJson['data'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      } else {
        throw ApiException('Dữ liệu danh sách task không hợp lệ');
      }

      // Fetch details and merge them into the tasks
      try {
        final detailsUri = _buildUri('/api/TaskDetails');
        final detailsResponse = await _get(detailsUri);
        if (detailsResponse.statusCode >= 200 &&
            detailsResponse.statusCode < 300) {
          final dynamic detailsJson = _decodeJson(detailsResponse.body);
          Map<String, dynamic> detailsMap = {};

          final detailsList = (detailsJson is Map<String, dynamic> &&
                  detailsJson.containsKey('data'))
              ? detailsJson['data'] as List
              : detailsJson as List;

          for (var detail in detailsList) {
            if (detail['taskId'] != null) {
              detailsMap[detail['taskId'].toString()] = detail;
            }
          }

          for (var taskJson in taskListJson) {
            final taskId = taskJson['id']?.toString();
            if (taskId != null && detailsMap.containsKey(taskId)) {
              final detailData = detailsMap[taskId];
              if (detailData['notes'] != null) {
                taskJson['taskNotes'] = detailData['notes'];
              }
            }
          }
        }
      } catch (e) {
        _log('Could not fetch or merge task details: $e');
      }

      return taskListJson.map(TaskModel.fromJson).toList();
    } on SocketException {
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra backend có đang chạy không.');
    } on TimeoutException {
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } on FormatException {
      throw ApiException('Phản hồi từ server không đúng định dạng JSON.');
    }
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'Yêu cầu thất bại';

    try {
      final dynamic errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic>) {
        message = (errorData['message'] ??
                errorData['title'] ??
                errorData['errors'] ??
                message)
            .toString();
      } else if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) message = response.body;
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  static dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      throw const FormatException('Empty response body');
    }
    return jsonDecode(body);
  }
}

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
    final uri = _buildUri('/api/Tasks/$id');

    try {
      final response = await _get(uri);

      _log('Status: ${response.statusCode}');

      _ensureSuccess(response);

      final dynamic data = _decodeJson(response.body);

      if (data is Map<String, dynamic>) {
        return TaskModel.fromJson(data);
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

      final dynamic data = _decodeJson(response.body);

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TaskModel.fromJson)
            .toList();
      }

      if (data is Map<String, dynamic>) {
        if (data.containsKey('data') && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map(TaskModel.fromJson)
              .toList();
        }
        return [TaskModel.fromJson(data)];
      }

      throw ApiException('Dữ liệu danh sách task không hợp lệ');
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

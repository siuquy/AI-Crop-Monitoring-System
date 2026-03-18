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

  static const String _baseUrl = 'http://10.0.2.2:5298';
  static const Duration _timeout = Duration(seconds: 15);

  static Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[TaskService] $message');
    }
  }

  static Future<List<TaskModel>> getTasks() async {
    final uri = _buildUri('/api/Tasks');
    return _getTaskList(uri);
  }

  static Future<TaskModel> getTaskById(String id) async {
    final uri = _buildUri('/api/Tasks/$id');

    try {
      _log('GET $uri');

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      _log('Status: ${response.statusCode}');
      _log('Body: ${response.body}');

      _ensureSuccess(response);

      final dynamic data = _decodeJson(response.body);

      if (data is Map<String, dynamic>) {
        return TaskModel.fromJson(data);
      }

      throw ApiException('Dữ liệu task không hợp lệ');
    } on SocketException {
      throw ApiException(
        'Không thể kết nối tới server. Hãy kiểm tra backend có đang chạy không.',
      );
    } on TimeoutException {
      throw ApiException(
        'Server phản hồi quá lâu. Vui lòng thử lại.',
      );
    } on FormatException {
      throw ApiException(
        'Phản hồi từ server không đúng định dạng JSON.',
      );
    }
  }

  static Future<List<TaskModel>> _getTaskList(Uri uri) async {
    try {
      _log('GET $uri');

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      _log('Status: ${response.statusCode}');
      _log('Body: ${response.body}');

      _ensureSuccess(response);

      final dynamic data = _decodeJson(response.body);

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(TaskModel.fromJson)
            .toList();
      }

      if (data is Map<String, dynamic>) {
        return [TaskModel.fromJson(data)];
      }

      throw ApiException('Dữ liệu danh sách task không hợp lệ');
    } on SocketException {
      throw ApiException(
        'Không thể kết nối tới server. Hãy kiểm tra backend có đang chạy không.',
      );
    } on TimeoutException {
      throw ApiException(
        'Server phản hồi quá lâu. Vui lòng thử lại.',
      );
    } on FormatException {
      throw ApiException(
        'Phản hồi từ server không đúng định dạng JSON.',
      );
    }
  }

  static List<dynamic> _extractData(dynamic json) {
    if (json is Map<String, dynamic> && json.containsKey('data')) {
      return json['data'] as List<dynamic>;
    }
    if (json is List) return json;
    throw ApiException('Format API không hợp lệ');
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Yêu cầu thất bại';

    try {
      final dynamic errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        if (errorData['message'] != null) {
          message = errorData['message'].toString();
        } else if (errorData['title'] != null) {
          message = errorData['title'].toString();
        } else if (errorData['errors'] != null) {
          message = errorData['errors'].toString();
        }
      } else if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body;
      }
    }

    throw ApiException(
      message,
      statusCode: response.statusCode,
    );
  }

  static dynamic _decodeJson(String body) {
    if (body.trim().isEmpty) {
      throw const FormatException('Empty response body');
    }
    return jsonDecode(body);
  }
}

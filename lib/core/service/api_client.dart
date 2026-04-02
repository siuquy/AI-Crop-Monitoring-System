import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Định nghĩa một lớp Exception chung cho toàn bộ ứng dụng
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

class ApiClient {
  // Sử dụng mẫu Singleton để đảm bảo chỉ có một instance của ApiClient
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  String? _authToken;
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5298'; // Sử dụng HTTP và cổng 5298 cho web
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5298'; // Sử dụng HTTP và cổng 5298 cho Android emulator
    }
    // Dành cho iOS hoặc các nền tảng khác
    return 'http://localhost:5298'; // Sử dụng HTTP và cổng 5298 cho iOS/other
  }

  static const Duration _timeout = Duration(seconds: 10);

  void setAuthToken(String? token) {
    _authToken = token;
    _log(token != null
        ? 'Auth token has been set.'
        : 'Auth token has been cleared.');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ApiClient] $message');
    }
  }

  Uri _buildUri(String path) {
    final effectivePath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${_baseUrl}$effectivePath');
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final uri = _buildUri(path);
    _log('GET $uri');
    try {
      final response = await http
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException {
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    }
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('POST $uri');
    try {
      final response = await http
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException {
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    File? file,
    String fileField = 'file',
  }) async {
    final uri = _buildUri(path);
    _log('POST (Multipart) $uri');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getHeaders());

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException {
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    _log('Response: ${response.statusCode} for ${response.request?.url}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw ApiException('Phản hồi từ server không đúng định dạng JSON.');
      }
    } else {
      String errorMessage = 'Yêu cầu thất bại (Mã lỗi: ${response.statusCode})';
      if (response.body.isNotEmpty) {
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map<String, dynamic>) {
            // Cố gắng tìm thông báo lỗi trong các key phổ biến
            errorMessage = errorJson['message'] ??
                errorJson['title'] ??
                errorJson['error'] ??
                errorMessage;
          }
        } catch (e) {
          // Body không phải là JSON, nhưng vẫn có thể chứa thông tin lỗi dạng text
          _log(
              'Không thể phân tích body của lỗi dưới dạng JSON. Body: ${response.body}');
        }
      }
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}

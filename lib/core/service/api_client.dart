import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../screens/task/api_config.dart';

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

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class ApiClient {
  ApiClient._privateConstructor() {
    HttpOverrides.global = DevHttpOverrides();
  }
  static final ApiClient instance = ApiClient._privateConstructor();

  String? _authToken;
  static String get _baseUrl {
    return ApiConfig.baseUrl;
  }

  static const Duration _timeout = Duration(seconds: 60);

  String? get authToken => _authToken;

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
      'Content-Type': 'application/json; charset=UTF-8',
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
    } on SocketException catch (e) {
      _log('SocketException on GET $uri: $e');
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException catch (e) {
      _log('TimeoutException on GET $uri: $e');
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } catch (e) {
      _log('Unexpected error on GET $uri: $e');
      throw ApiException('Đã xảy ra lỗi không mong muốn: $e');
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
    } on SocketException catch (e) {
      _log('SocketException on POST $uri: $e');
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException catch (e) {
      _log('TimeoutException on POST $uri: $e');
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } catch (e) {
      _log('Unexpected error on POST $uri: $e');
      throw ApiException('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('PUT $uri');
    try {
      final response = await http
          .put(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('SocketException on PUT $uri: $e');
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException catch (e) {
      _log('TimeoutException on PUT $uri: $e');
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } catch (e) {
      _log('Unexpected error on PUT $uri: $e');
      throw ApiException('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final uri = _buildUri(path);
    _log('PATCH $uri');
    try {
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('SocketException on PATCH $uri: $e');
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException catch (e) {
      _log('TimeoutException on PATCH $uri: $e');
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } catch (e) {
      _log('Unexpected error on PATCH $uri: $e');
      throw ApiException('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<File>? files,
    String fileField = 'file',
  }) async {
    final uri = _buildUri(path);
    _log('POST (Multipart) $uri');
    try {
      final request = http.MultipartRequest('POST', uri);
      final headers = _getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final ext = file.path.split('.').last.toLowerCase();
          MediaType contentType = MediaType('image', 'jpeg');
          if (ext == 'png') {
            contentType = MediaType('image', 'png');
          } else if (ext == 'webp') {
            contentType = MediaType('image', 'webp');
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              fileField,
              file.path,
              contentType: contentType,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('SocketException on Multipart POST $uri: $e');
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException catch (e) {
      _log('TimeoutException on Multipart POST $uri: $e');
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } catch (e) {
      _log('Unexpected error on Multipart POST $uri: $e');
      throw ApiException('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  Future<dynamic> putMultipart(
    String path, {
    Map<String, String>? fields,
    File? file,
    String fileField = 'file',
  }) async {
    final uri = _buildUri(path);
    _log('PUT (Multipart) $uri');
    try {
      final request = http.MultipartRequest('PUT', uri);
      final headers = _getHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (file != null) {
        final ext = file.path.split('.').last.toLowerCase();
        MediaType contentType = MediaType('image', 'jpeg');
        if (ext == 'png') {
          contentType = MediaType('image', 'png');
        } else if (ext == 'webp') {
          contentType = MediaType('image', 'webp');
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: contentType,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException catch (e) {
      _log('SocketException on Multipart PUT $uri: $e');
      throw ApiException(
          'Không thể kết nối tới server. Hãy kiểm tra kết nối mạng và backend.');
    } on TimeoutException catch (e) {
      _log('TimeoutException on Multipart PUT $uri: $e');
      throw ApiException('Server phản hồi quá lâu. Vui lòng thử lại.');
    } catch (e) {
      _log('Unexpected error on Multipart PUT $uri: $e');
      throw ApiException('Đã xảy ra lỗi không mong muốn: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    _log('Response: ${response.statusCode} for ${response.request?.url}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiException('Phản hồi từ server không đúng định dạng JSON.');
      }
    } else {
      String errorMessage = 'Yêu cầu thất bại (Mã lỗi: ${response.statusCode})';
      if (response.bodyBytes.isNotEmpty) {
        try {
          final errorJson = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorJson is Map<String, dynamic>) {
            errorMessage = errorJson['message'] ??
                errorJson['title'] ??
                errorJson['error'] ??
                errorMessage;
          }
        } catch (e) {
          _log(
              'Không thể phân tích body của lỗi dưới dạng JSON. Body: ${utf8.decode(response.bodyBytes)}');
        }
      }

      if (response.statusCode == 403) {
        errorMessage =
            'Tài khoản không có quyền truy cập dữ liệu này (Lỗi 403). Vui lòng đăng nhập bằng tài khoản Quản lý.';
      } else if (response.statusCode == 401) {
        errorMessage =
            'Phiên đăng nhập đã hết hạn (Lỗi 401). Vui lòng đăng nhập lại.';
      }

      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}

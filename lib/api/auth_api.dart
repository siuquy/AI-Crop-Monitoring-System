import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoginResponse {
  final bool success;
  final String message;
  final dynamic data;

  LoginResponse({required this.success, required this.message, this.data});
}

class AuthApi {
  static const String _baseUrl =
      'https://10.0.2.2:7093'; 
  static const Duration _timeout = Duration(seconds: 8);

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AuthApi] $message');
    }
  }

  Future<http.Response> _post(Uri uri,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    _log('POST $uri');
    var response = await http
        .post(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        )
        .timeout(_timeout);
    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        final newUri = uri.resolve(location);
        _log('Following temporary redirect to $newUri for POST');
        response = await http
            .post(
              newUri,
              headers: headers,
              body: body,
              encoding: encoding,
            )
            .timeout(_timeout);
      }
    }
    return response;
  }

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri =
        _buildUri('/api/Auth/login'); 

    try {
      final response = await _post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _log('Login Status: ${response.statusCode}');
      _log('Login Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return LoginResponse(
          success: true,
          message: data['message'] ?? 'Đăng nhập thành công',
          data: data['data'], 
        );
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return LoginResponse(
          success: false,
          message: errorData['message'] ?? 'Đăng nhập thất bại',
        );
      }
    } on SocketException {
      return LoginResponse(
          success: false,
          message:
              'Không thể kết nối tới server. Hãy kiểm tra backend có đang chạy không.');
    } on TimeoutException {
      return LoginResponse(
          success: false,
          message: 'Server phản hồi quá lâu. Vui lòng thử lại.');
    } on FormatException {
      return LoginResponse(
          success: false,
          message: 'Phản hồi từ server không đúng định dạng JSON.');
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi không xác định: $e');
    }
  }
}

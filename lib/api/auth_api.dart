import '../core/service/api_client.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class LoginResponse {
  final bool success;
  final String message;
  final dynamic data;

  LoginResponse({required this.success, required this.message, this.data});
}

class AuthApi {
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await ApiClient.instance.post(
        '/api/Auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final responseData = data?['data'];
      final token = responseData?['token'] as String?;

      if (token != null && token.isNotEmpty) {
        ApiClient.instance.setAuthToken(token);
      } else {
        // Log a warning if no token is received, but don't block login if success is true.
        // This assumes that if success is true, the login itself was fine,
        // but the token might be handled differently or is not yet implemented on backend.
        if (kDebugMode) {
          debugPrint(
              '[AuthApi] Warning: Login successful but no authentication token received from server.');
        }
      }
      return LoginResponse(
        success: true,
        message: data?['message'] ?? 'Đăng nhập thành công',
        data: responseData,
      );
    } on ApiException catch (e) {
      return LoginResponse(success: false, message: e.message);
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi không xác định: $e');
    }
  }

  Future<void> logout() async {
    // Xóa token đã lưu
    ApiClient.instance.setAuthToken(null);
  }
}

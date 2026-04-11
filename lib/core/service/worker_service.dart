import 'dart:convert';
import 'package:acmms/models/worker.dart';

import 'api_client.dart';

class WorkerService {
  static Future<Worker> getCurrentWorker() async {
    try {
      final token = ApiClient.instance.authToken;
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final resp = utf8.decode(base64Url.decode(normalized));
          final decodedToken = jsonDecode(resp);

          final userId = decodedToken['nameid'] ?? decodedToken['sub'] ?? '';
          final email = decodedToken['email'] ?? '';
          final role = decodedToken['role'] ?? 'Worker';
          final fullName =
              decodedToken['unique_name'] ?? email.split('@').first;

          return Worker(
            id: userId,
            fullName: fullName,
            role: role,
            email: email,
          );
        }
      }
      throw ApiException('Không tìm thấy thông tin đăng nhập hợp lệ.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi lấy thông tin người dùng hiện tại: $e');
    }
  }

  static Future<List<Worker>> getWorkers() async {
    try {
      final apiClient = ApiClient.instance;
      final response =
          await apiClient.get('/api/Staff'); // Cập nhật sang API mới
      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        final List<dynamic> workerData = response['data'];
        return workerData.map((json) {
          // Ánh xạ lại các trường từ API mới cho tương thích với model cũ
          if (json['id'] == null && json['userId'] != null) {
            json['id'] = json['userId'];
          }
          if (json['fullName'] == null && json['fullname'] != null) {
            json['fullName'] = json['fullname'];
          }
          if (json['role'] == null && json['roleName'] != null) {
            json['role'] = json['roleName'];
          }
          return Worker.fromJson(json);
        }).toList();
      } else {
        return [];
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return [];
      }
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi phân tích danh sách người dùng: $e');
    }
  }
}

import 'package:acmms/models/worker.dart';

import 'api_client.dart';

class WorkerService {
  static Future<Worker> getCurrentWorker() async {
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.get('/api/Staffs/me');

      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        final json =
            Map<String, dynamic>.from(response['data'] as Map<String, dynamic>);

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
      }
      throw ApiException('Không thể lấy thông tin người dùng từ server.');
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
      final response = await apiClient.get('/api/Staff');
      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        final List<dynamic> workerData = response['data'];
        return workerData.map((json) {
          final data = Map<String, dynamic>.from(json as Map<String, dynamic>);
          // Ánh xạ lại các trường từ API mới cho tương thích với model cũ
          if (data['id'] == null && data['userId'] != null) {
            data['id'] = data['userId'];
          }
          if (data['fullName'] == null && data['fullname'] != null) {
            data['fullName'] = data['fullname'];
          }
          if (data['role'] == null && data['roleName'] != null) {
            data['role'] = data['roleName'];
          }
          return Worker.fromJson(data);
        }).toList();
      } else {
        return [];
      }
    } on ApiException catch (e) {
      if (e.statusCode == 403 || e.statusCode == 404) {
        return [];
      }
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi phân tích danh sách người dùng: $e');
    }
  }
}

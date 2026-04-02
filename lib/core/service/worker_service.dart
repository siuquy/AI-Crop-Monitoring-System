import 'package:acmms/models/worker.dart';

import 'api_client.dart';

class WorkerService {
  /// Lấy thông tin của người dùng đang đăng nhập.
  ///
  /// LƯU Ý: API hiện tại (`/api/Workers`) trả về một danh sách TẤT CẢ người dùng.
  /// Để màn hình Cài đặt hoạt động, phương thức này đang tạm thời lấy người dùng đầu tiên
  /// trong danh sách đó.
  ///
  /// TODO: Thay thế phương thức này bằng một API call chính xác để lấy
  /// thông tin của người dùng đã đăng nhập, ví dụ: `/api/workers/me` hoặc `/api/auth/profile`.
  static Future<Worker> getCurrentWorker() async {
    try {
      // Tạm thời lấy người dùng đầu tiên từ danh sách tất cả người dùng.
      final allWorkers = await getWorkers();
      if (allWorkers.isNotEmpty) {
        return allWorkers.first;
      } else {
        throw ApiException('Không tìm thấy người dùng nào.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi lấy thông tin người dùng hiện tại: $e');
    }
  }

  /// Lấy danh sách tất cả các worker từ API.
  static Future<List<Worker>> getWorkers() async {
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.get('/api/Workers');
      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        final List<dynamic> workerData = response['data'];
        return workerData.map((json) => Worker.fromJson(json)).toList();
      } else {
        throw ApiException(
            response?['message'] ?? 'Không tải được danh sách người dùng.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi phân tích danh sách người dùng: $e');
    }
  }
}

import 'dart:io';
import '../../models/report.dart';
import 'api_client.dart';
import 'worker_service.dart';

class ReportService {
  static Future<List<Report>> getReports() async {
    try {
      final apiClient = ApiClient.instance;
      // Gọi endpoint /api/Reports.
      // Lưu ý: ApiClient được cấu hình cho một URL cơ sở cụ thể (ví dụ: http://...:5298).
      // Hãy đảm bảo URL này khớp với URL backend từ lệnh curl của bạn (https://localhost:7093).
      final response = await apiClient.get('/api/reports');

      // API có thể trả về dữ liệu được gói trong cấu trúc { success: bool, data: [...] }
      if (response is Map<String, dynamic> && response['data'] is List) {
        final List<dynamic> reportData = response['data'];
        return reportData.map((json) => Report.fromJson(json)).toList();
      } else {
        throw ApiException(
            'Định dạng dữ liệu báo cáo không hợp lệ.'); // Lỗi này xảy ra khi API không trả về một Map có chứa list 'data'.
      }
    } on ApiException {
      rethrow; // Ném lại các exception từ API để UI xử lý.
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi phân tích báo cáo: $e');
    }
  }

  static Future<void> createReport({
    required String title,
    required String description,
    required File image,
    required String farmId,
    required String plotId,
    required String bedId,
  }) async {
    try {
      final worker = await WorkerService.getCurrentWorker();
      final submitDate = DateTime.now().toUtc().toIso8601String();
      final apiClient = ApiClient.instance;
      // Backend endpoint for creating a report, assuming it's a multipart request
      // The 'fileField' should match what the backend API expects for the image file.
      final response = await apiClient.postMultipart(
        '/api/reports',
        fields: {
          'workerId': worker.id,
          'title': title,
          'description': description,
          'farmId': farmId,
          'plotId': plotId,
          'bedId': bedId,
          'submitDate': submitDate,
          'status':
              'active', // Thêm trạng thái ban đầu cho báo cáo, khớp với ví dụ curl
        },
        file: image,
        fileField:
            'imageFile', // Common name for file field, confirm with backend
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        // API call was successful. The API returns a success message, not the created object.
        return;
      } else {
        final message =
            response is Map<String, dynamic> ? response['message'] : null;
        throw ApiException(message ??
            'Không thể tạo báo cáo. Phản hồi từ server không hợp lệ.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Đã xảy ra lỗi không mong muốn khi tạo báo cáo: $e');
    }
  }

  static Future<Report> updateReport({
    required String reportId,
    required String description,
    File? newImage,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      // Assuming a PUT request to /api/Reports/{id}
      final response = await apiClient.putMultipart(
        '/api/reports/$reportId',
        fields: {
          'description': description,
        },
        file: newImage,
        fileField: 'imageFile',
      );

      // Tương tự như createReport, ApiClient đã trả về phần 'data'.
      return Report.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi cập nhật báo cáo: $e');
    }
  }
}

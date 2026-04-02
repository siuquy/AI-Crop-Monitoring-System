import 'dart:io';
import '../../models/report.dart';
import 'api_client.dart';

class ReportService {
  static Future<List<Report>> getReports() async {
    try {
      final apiClient = ApiClient.instance;
      // Gọi endpoint /api/Reports.
      // Lưu ý: ApiClient được cấu hình cho một URL cơ sở cụ thể (ví dụ: http://...:5298).
      // Hãy đảm bảo URL này khớp với URL backend từ lệnh curl của bạn (https://localhost:7093).
      final response = await apiClient.get('/api/Reports');

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        final List<dynamic> reportData = response['data'];
        return reportData.map((json) => Report.fromJson(json)).toList();
      } else {
        throw ApiException(response?['message'] ?? 'Không tải được báo cáo.');
      }
    } on ApiException {
      rethrow; // Ném lại các exception từ API để UI xử lý.
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi phân tích báo cáo: $e');
    }
  }

  static Future<Report> createReport({
    required String title,
    required String description,
    required File image,
    required String farmId,
    required String plotId,
    required String bedId,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      // Backend endpoint for creating a report, assuming it's a multipart request
      // The 'fileField' should match what the backend API expects for the image file.
      final response = await apiClient.postMultipart(
        '/api/Reports',
        fields: {
          'title': title,
          'description': description,
          'farmId': farmId,
          'plotId': plotId,
          'bedId': bedId,
        },
        file: image,
        fileField:
            'imageFile', // Common name for file field, confirm with backend
      );

      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        // Assuming the API returns the newly created report object in the 'data' field.
        return Report.fromJson(response['data']);
      } else {
        throw ApiException(response?['message'] ?? 'Không tạo được báo cáo.');
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
        '/api/Reports/$reportId',
        fields: {
          'description': description,
        },
        file: newImage,
        fileField: 'imageFile',
      );

      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        return Report.fromJson(response['data']);
      } else {
        throw ApiException(
            response?['message'] ?? 'Không cập nhật được báo cáo.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi cập nhật báo cáo: $e');
    }
  }
}

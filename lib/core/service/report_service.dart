import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/report.dart';
import 'api_client.dart';
import 'worker_service.dart';

class ReportService {
  // --- Caching Mechanism ---
  static List<Report>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 1);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ReportService] $message');
    }
  }

  /// Lấy danh sách báo cáo.
  ///
  /// [forceRefresh] nếu là true, sẽ bỏ qua cache và lấy dữ liệu mới từ API.
  static Future<List<Report>> getReports({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Trả về danh sách báo cáo từ cache (${_cache!.length} mục).');
      return _cache!;
    }

    _log('Đang tải danh sách báo cáo từ API...');
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.get('/api/reports');

      if (response is Map<String, dynamic> && response['data'] is List) {
        final List<dynamic> reportData = response['data'];
        final reports =
            reportData.map((json) => Report.fromJson(json)).toList();

        _cache = reports;
        _cacheTime = DateTime.now();
        _log('Đã tải và cache ${reports.length} báo cáo.');
        return reports;
      } else {
        throw ApiException('Định dạng dữ liệu báo cáo không hợp lệ.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi phân tích báo cáo: $e');
    }
  }

  /// Tạo báo cáo mới.
  ///
  /// API chỉ nhận JSON với các trường: workerId, title, description, status, submitDate.
  /// Các trường farmId, plotId, bedId, image không được API hỗ trợ hiện tại.
  static Future<void> createReport({
    required String title,
    required String description,
    File? image, // Giữ lại tham số để tương thích, nhưng API chưa hỗ trợ
    String? farmId,
    String? plotId,
    String? bedId,
  }) async {
    try {
      final worker = await WorkerService.getCurrentWorker();
      final submitDate = DateTime.now().toUtc().toIso8601String();
      final apiClient = ApiClient.instance;

      // API POST /api/Reports nhận JSON, không phải multipart
      final response = await apiClient.post(
        '/api/reports',
        body: {
          'workerId': worker.id,
          'title': title,
          'description': description,
          'status': 'active',
          'submitDate': submitDate,
        },
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
        // Xóa cache để danh sách báo cáo được làm mới lần sau
        _cache = null;
        _cacheTime = null;
        _log('Tạo báo cáo thành công.');
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
      final response = await apiClient.putMultipart(
        '/api/reports/$reportId',
        fields: {
          'description': description,
        },
        file: newImage,
        fileField: 'imageFile',
      );

      return Report.fromJson(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
          'Đã xảy ra lỗi không mong muốn khi cập nhật báo cáo: $e');
    }
  }
}
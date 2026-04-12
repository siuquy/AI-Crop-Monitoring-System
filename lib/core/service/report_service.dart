import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/report.dart';
import 'api_client.dart';
import 'worker_service.dart';

class ReportService {
  static List<Report>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 1);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ReportService] $message');
    }
  }

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
      final response = await apiClient.get('/api/Reports');

      if (response is Map<String, dynamic> && response['data'] is List) {
        final List<dynamic> reportData = response['data'];
        final reports = reportData.map((json) {
          if (json['id'] == null && json['reportId'] != null) {
            json['id'] = json['reportId'];
          }
          return Report.fromJson(json);
        }).toList();

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

  static Future<String?> getOwnerRoleId() async {
    _log('Đang tải danh sách vai trò để lấy Owner ID...');
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.get('/api/Auth/roles');

      if (response is Map<String, dynamic> && response['success'] == true) {
        final List<dynamic> roles = response['data'];
        final ownerRole = roles.firstWhere(
          (role) => role['roleName'] == 'Owner',
          orElse: () => null,
        );
        return ownerRole?['roleId']?.toString();
      }
      return null;
    } catch (e) {
      _log('Lỗi khi lấy ID của Owner: $e');
      return null;
    }
  }

  static Future<void> createReport({
    required String title,
    required String description,
    String? reportType = 'Diseases',
    List<File>? images,
    String? plotId,
    String? bedId,
    String? seasonId,
    String? ownerId,
    Map<String, dynamic>? aiResults,
  }) async {
    try {
      final worker = await WorkerService.getCurrentWorker();
      final submitDate = DateTime.now().toUtc().toIso8601String();
      final apiClient = ApiClient.instance;
      dynamic response;

      String? aiResultsJsonStr;
      if (aiResults != null) {
        aiResultsJsonStr = jsonEncode(aiResults);
      }

      // Gọi API dạng JSON
      response = await apiClient.post(
        '/api/Reports',
        body: {
          'createdBy': worker.id,
          'title': title,
          'description': description,
          'status': 'SENT_TO_OWNER',
          'submitDate': submitDate,
          'updatedAt': submitDate,
          'UpdatedAt': submitDate,
          'update_at': submitDate,
          'updated_at': submitDate, 
          if (reportType != null) 'reportType': reportType,
          if (plotId != null) 'plotId': plotId,
          if (bedId != null) 'bedId': bedId,
          if (seasonId != null) 'seasonId': seasonId,
          if (seasonId != null) 'SeasonId': seasonId,
          if (seasonId != null) 'season_id': seasonId,
          if (ownerId != null) 'ownerId': ownerId,
          if (ownerId != null) 'owner_id': ownerId,
          if (aiResultsJsonStr != null) 'aiResultsJson': aiResultsJsonStr,
          if (aiResultsJsonStr != null) 'AiResultsJson': aiResultsJsonStr,
          if (aiResultsJsonStr != null) 'ai_results_json': aiResultsJsonStr,
        },
      );

      if (response is Map<String, dynamic> && response['success'] == true) {
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
        '/api/Reports/$reportId',
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

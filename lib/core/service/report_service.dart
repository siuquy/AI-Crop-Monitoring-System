import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/report.dart';
import 'api_client.dart';

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
      final apiClient = ApiClient.instance;

      final fields = <String, String>{
        'Title': title,
        'Description': description,
      };

      if (reportType != null) fields['ReportType'] = reportType;
      if (plotId != null) fields['PlotId'] = plotId;
      if (bedId != null) fields['BedId'] = bedId;
      if (seasonId != null) fields['SeasonId'] = seasonId;
      if (ownerId != null) fields['OwnerId'] = ownerId;
      if (aiResults != null) fields['AiResultsJson'] = jsonEncode(aiResults);

      // Gửi API dạng Multipart Form-Data
      final response = await apiClient.postMultipart(
        '/api/Reports',
        fields: fields,
        files: images,
        fileField: 'images', // Truyền mảng ảnh theo đúng định nghĩa Swagger
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

  // API GET: Lấy danh sách file đính kèm
  static Future<List<dynamic>> getAttachments({
    required String objectId,
    required String objectType,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient
          .get('/api/Attachments?objectType=$objectType&objectId=$objectId');

      if (response is Map<String, dynamic> && response['success'] == true) {
        return response['data'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      _log('Lỗi khi lấy file đính kèm: $e');
      return [];
    }
  }

  // API POST: Tải lên file đính kèm
  static Future<void> uploadAttachment({
    required File file,
    required String objectId,
    required String objectType,
    String attachmentType = 'Image',
    String description = 'Ảnh đính kèm',
  }) async {
    try {
      final apiClient = ApiClient.instance;
      await apiClient.postMultipart(
        '/api/Attachments/upload',
        fields: {
          'objectType': objectType,
          'objectId': objectId,
          'attachmentType': attachmentType,
          'description': description,
        },
        files: [file],
        fileField: 'file', // Tên field binary theo định nghĩa Swagger
      );
      _log('Đã upload thành công 1 ảnh đính kèm cho $objectType ($objectId).');
    } catch (e) {
      _log('Lỗi khi upload file đính kèm: $e');
      // Không throw exception để tránh gián đoạn ứng dụng nếu chỉ lỗi ảnh
    }
  }
}

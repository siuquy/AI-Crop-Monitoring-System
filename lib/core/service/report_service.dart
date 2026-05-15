import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/report.dart';

class ReportService {
  static Future<List<Map<String, dynamic>>> getAttachments(
      String objectType, String objectId) async {
    try {
      final response = await ApiClient.instance
          .get('/api/Attachments?objectType=$objectType&objectId=$objectId');
      if (response != null && response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi lấy attachments: $e');
      return [];
    }
  }

  static Future<void> uploadAttachments(
      String objectType, String objectId, List<File> files) async {
    if (files.isEmpty) return;
    try {
      final fields = {
        'objectType': objectType,
        'objectId': objectId,
        'attachmentType':
            'none', // Thêm trường này theo yêu cầu validation của backend
      };

      await ApiClient.instance.postMultipart(
        '/api/Attachments/upload',
        fields: fields,
        files: files,
        fileField: 'file', // Sửa lại tên trường file theo yêu cầu của backend
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi upload attachments: $e');
      rethrow;
    }
  }

  static Future<List<Report>> getReports() async {
    try {
      final response = await ApiClient.instance.get('/api/Reports');
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        return data
            .map((json) => Report.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Report>> enrichReportsWithAttachments(
      List<Report> reports) async {
    return await Future.wait(reports.map((report) async {
      try {
        final attachments = await getAttachments('report', report.id);
        if (attachments.isEmpty) return report;

        final urls = attachments
            .map((a) => a['secureUrl'] ?? a['fileUrl'])
            .where((url) => url != null)
            .map((e) => e.toString())
            .toList();

        if (urls.isEmpty) return report;

        return Report(
          id: report.id,
          reportNo: report.reportNo,
          title: report.title,
          description: report.description,
          reportType: report.reportType,
          createdBy: report.createdBy,
          creatorName: report.creatorName,
          ownerId: report.ownerId,
          ownerName: report.ownerName,
          plotId: report.plotId,
          bedId: report.bedId,
          seasonId: report.seasonId,
          diseaseName: report.diseaseName,
          imageUrl: report.imageUrl ?? urls.first,
          imageUrls: urls,
          createdAt: report.createdAt,
          submitDate: report.submitDate,
          updatedAt: report.updatedAt,
          status: report.status,
          ownerComment: report.ownerComment,
          workerName: report.workerName,
          aiResults: report.aiResults,
          aiResultsJson: report.aiResultsJson,
        );
      } catch (e) {
        return report;
      }
    }));
  }

  static Future<void> createReport({
    required String title,
    required String description,
    required String reportType,
    required List<File> images,
    String? diseaseName,
    String? plotId,
    String? bedId,
    Map<String, dynamic>? aiResults,
    String? seasonId,
    String? ownerId,
  }) async {
    try {
      // Đính kèm dữ liệu AI vào description để phòng trường hợp Backend không có cột lưu JSON riêng
      String finalDescription = description;
      if (aiResults != null) {
        finalDescription =
            '$description\n\n---AI_RESULT_JSON---\n${jsonEncode(aiResults)}';
      }

      final Map<String, String> fields = {
        'title': title,
        'description': finalDescription,
        'reportType': reportType,
      };

      if (diseaseName != null && diseaseName.isNotEmpty)
        fields['diseaseName'] = diseaseName;
      if (plotId != null && plotId.isNotEmpty) fields['plotId'] = plotId;
      if (bedId != null && bedId.isNotEmpty) fields['bedId'] = bedId;
      if (seasonId != null && seasonId.isNotEmpty)
        fields['seasonId'] = seasonId;
      if (ownerId != null && ownerId.isNotEmpty) fields['ownerId'] = ownerId;
      if (aiResults != null) fields['aiResultsJson'] = jsonEncode(aiResults);

      // Gửi dưới dạng Form-Data thay vì JSON để Backend ánh xạ dữ liệu chính xác
      final response = await ApiClient.instance
          .postMultipart('/api/Reports', fields: fields);

      if (images.isNotEmpty &&
          response != null &&
          response['success'] == true) {
        final data = response['data'];
        // Đề phòng trường hợp API trả về thẳng chuỗi ID thay vì object Map
        final reportId =
            (data is Map) ? (data['id'] ?? data['reportId']) : data;
        if (reportId != null) {
          try {
            await uploadAttachments('report', reportId.toString(), images);
          } catch (e) {
            debugPrint('Lỗi tải ảnh đính kèm: $e');
            throw ApiException(
                'Báo cáo đã được tạo nhưng gặp lỗi khi tải ảnh: $e');
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateReport({
    required String reportId,
    required String description,
    File? newImage,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'description': description,
      };
      await ApiClient.instance.patch('/api/Reports/$reportId', body: body);

      if (newImage != null) {
        await uploadAttachments('report', reportId, [newImage]);
      }
    } catch (e) {
      rethrow;
    }
  }
}

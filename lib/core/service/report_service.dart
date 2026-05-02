import 'dart:convert';
import 'dart:io';
import 'api_client.dart';
import '../../models/report.dart';

class ReportService {
  static Future<List<Report>> getReports() async {
    try {
      final response = await ApiClient.instance.get('/api/Reports');
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        // Ánh xạ sang model Report
        return data
            .map((json) => Report.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> createReport({
    required String title,
    required String description,
    required String reportType,
    required List<File> images,
    String? plotId,
    String? bedId,
    Map<String, dynamic>? aiResults,
    String? seasonId,
    String? ownerId,
  }) async {
    try {
      if (images.isNotEmpty) {
        final Map<String, String> fields = {
          'title': title,
          'description': description,
          'reportType': reportType,
        };

        if (plotId != null && plotId.isNotEmpty) fields['plotId'] = plotId;
        if (bedId != null && bedId.isNotEmpty) fields['bedId'] = bedId;
        if (seasonId != null && seasonId.isNotEmpty)
          fields['seasonId'] = seasonId;
        if (ownerId != null && ownerId.isNotEmpty) fields['ownerId'] = ownerId;
        if (aiResults != null) fields['aiResultsJson'] = jsonEncode(aiResults);

        await ApiClient.instance.postMultipart(
          '/api/Reports',
          fields: fields,
          files: images,
          fileField: 'files', // Có thể đổi thành 'images' tùy backend
        );
      } else {
        final Map<String, dynamic> body = {
          'title': title,
          'description': description,
          'reportType': reportType,
        };
        // Code cũ đã được rút gọn logic
        if (plotId != null && plotId.isNotEmpty) body['plotId'] = plotId;
        if (bedId != null && bedId.isNotEmpty) body['bedId'] = bedId;
        if (seasonId != null && seasonId.isNotEmpty)
          body['seasonId'] = seasonId;
        if (ownerId != null && ownerId.isNotEmpty) body['ownerId'] = ownerId;
        if (aiResults != null) body['aiResultsJson'] = jsonEncode(aiResults);

        await ApiClient.instance.post('/api/Reports', body: body);
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
      if (newImage != null) {
        final Map<String, String> fields = {
          'description': description,
        };
        await ApiClient.instance.putMultipart(
          '/api/Reports/$reportId', // Endpoint upload multipart của update
          fields: fields,
          file: newImage,
          fileField: 'file', // Có thể đổi theo chuẩn của backend
        );
      } else {
        final Map<String, dynamic> body = {
          'description': description,
        };
        await ApiClient.instance.patch('/api/Reports/$reportId', body: body);
      }
    } catch (e) {
      rethrow;
    }
  }
}

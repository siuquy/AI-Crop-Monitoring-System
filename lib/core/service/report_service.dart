import 'dart:io';
import 'dart:convert';
import 'api_client.dart';
import '../../models/report.dart';

class ReportService {
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
    final Map<String, String> fields = {
      'Title': title,
      'Description': description,
      'ReportType': reportType,
    };

    if (plotId != null) fields['PlotId'] = plotId;
    if (bedId != null) fields['BedId'] = bedId;
    if (seasonId != null) fields['SeasonId'] = seasonId;
    if (ownerId != null) fields['OwnerId'] = ownerId;
    if (aiResults != null) fields['AiResultsJson'] = jsonEncode(aiResults);

    // API Client của bạn phải có phương thức `postMultipart` được hỗ trợ
    await ApiClient.instance.postMultipart(
      '/api/Reports',
      fields: fields,
      files: images,
      fileField: 'images',
    );
  }

  static Future<List<Report>> getReports() async {
    final response = await ApiClient.instance.get('/api/Reports');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Report.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<List<dynamic>> getAttachments({
    required String objectId,
    required String objectType,
  }) async {
    final response = await ApiClient.instance
        .get('/api/Attachments?objectId=$objectId&objectType=$objectType');

    if (response is List) return response;

    if (response is Map &&
        response['success'] == true &&
        response['data'] != null) {
      return response['data'] as List;
    }
    return [];
  }

  static Future<void> updateReport({
    required String reportId,
    required String description,
    File? newImage,
  }) async {
    final Map<String, String> fields = {'Description': description};

    if (newImage != null) {
      await ApiClient.instance.putMultipart(
        '/api/Reports/$reportId',
        fields: fields,
        file: newImage,
        fileField: 'images',
      );
    } else {
      await ApiClient.instance.put('/api/Reports/$reportId', body: fields);
    }
  }
}

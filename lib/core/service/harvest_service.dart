import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class HarvestService {
  static Future<void> createHarvest({
    required String plotId,
    required String seasonId,
    required String cropId,
    required String expectedDate,
    required num expectedQuantity,
    required String unit,
    required String status,
    required String notes,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "plotId": plotId,
        "seasonId": seasonId,
        "cropId": cropId,
        "expectedDate": expectedDate,
        "expectedQuantity": expectedQuantity,
        "unit": unit,
        "status": status,
        "notes": notes,
        "startDate": startDate,
        "endDate": endDate
      };

      await ApiClient.instance.post('/api/harvests', body: body);
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi tạo harvest: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getHarvests({
    String? farmId,
    String? plotId,
    String? seasonId,
  }) async {
    try {
      String url = '/api/harvests';
      List<String> queryParams = [];
      if (farmId != null && farmId.isNotEmpty)
        queryParams.add('farmId=$farmId');
      if (plotId != null && plotId.isNotEmpty)
        queryParams.add('plotId=$plotId');
      if (seasonId != null && seasonId.isNotEmpty)
        queryParams.add('seasonId=$seasonId');

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await ApiClient.instance.get(url);
      List<Map<String, dynamic>> results = [];
      if (response != null && response is List) {
        results = List<Map<String, dynamic>>.from(response);
      } else if (response != null && response['data'] is List) {
        results = List<Map<String, dynamic>>.from(response['data']);
      }

      // Lọc thêm ở client đề phòng API không hỗ trợ query string
      if (plotId != null && plotId.isNotEmpty) {
        results =
            results.where((h) => h['plotId']?.toString() == plotId).toList();
      }
      if (seasonId != null && seasonId.isNotEmpty) {
        results = results
            .where((h) => h['seasonId']?.toString() == seasonId)
            .toList();
      }

      return results;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi lấy danh sách harvest: $e');
      return [];
    }
  }

  static Future<bool> submitHarvest({
    required String plotId,
    required String seasonId,
    required String cropName,
    required double quantity,
    required String unit,
    required String quality,
    required DateTime harvestDate,
    required String notes,
    File? image,
  }) async {
    try {
      final Map<String, String> fields = {
        "plotId": plotId,
        "seasonId": seasonId,
        "cropName": cropName,
        "quantity": quantity.toString(),
        "unit": unit,
        "quality": quality,
        "harvestDate": harvestDate.toIso8601String(),
        "notes": notes,
      };

      if (image != null) {
        await ApiClient.instance.postMultipart(
          '/api/harvests',
          fields: fields,
          files: [image],
        );
      } else {
        final Map<String, dynamic> body = {
          "plotId": plotId,
          "seasonId": seasonId,
          "cropName": cropName,
          "quantity": quantity,
          "unit": unit,
          "quality": quality,
          "harvestDate": harvestDate.toIso8601String(),
          "notes": notes,
        };
        await ApiClient.instance.post('/api/harvests', body: body);
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi submit harvest: $e');
      return false;
    }
  }
}

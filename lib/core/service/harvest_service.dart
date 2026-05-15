import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class HarvestService {
  static Future<List<Map<String, dynamic>>> getHarvests() async {
    try {
      final response = await ApiClient.instance.get('/api/harvests');
      if (response != null && response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi tải danh sách Harvests: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getHarvestDetail(String id) async {
    try {
      final response = await ApiClient.instance.get('/api/harvest-details/$id');
      if (response != null && response['success'] == true) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi tải Harvest Detail: $e');
      return null;
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
        'plotId': plotId,
        'seasonId': seasonId,
        'cropName': cropName,
        'quantity': quantity.toString(),
        'unit': unit,
        'quality': quality,
        'harvestDate': harvestDate.toIso8601String(),
        'notes': notes,
      };

      if (image != null) {
        await ApiClient.instance.postMultipart(
          '/api/Harvests',
          fields: fields,
          files: [image],
          fileField: 'image', // Hoặc 'file' tùy API backend yêu cầu
        );
      } else {
        // Nếu không có ảnh thì gọi POST thông thường
        await ApiClient.instance.post('/api/Harvests', body: fields);
      }

      debugPrint('Ghi nhận thu hoạch thành công!');
      return true;
    } catch (e) {
      debugPrint('Ngoại lệ khi gửi thu hoạch: $e');
      throw Exception('Lỗi mạng hoặc server. Vui lòng thử lại.');
    }
  }
}

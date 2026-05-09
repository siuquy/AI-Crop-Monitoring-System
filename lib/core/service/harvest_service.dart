import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HarvestService {
  static const String baseUrl = 'https://api.example.com';

  static Future<Map<String, dynamic>> getSeasonToHarvestMap() async {
    try {
      return {};
    } catch (e) {
      debugPrint('Lỗi tải danh sách mùa vụ: $e');
      return {};
    }
  }

  static Future<bool> submitHarvest({
    required String plotId,
    required String cropName,
    required double quantity,
    required String unit,
    required String quality,
    required DateTime harvestDate,
    required String notes,
    File? image,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/api/Harvests');
      var request = http.MultipartRequest('POST', uri);

      request.fields['plotId'] = plotId;
      request.fields['cropName'] = cropName;
      request.fields['quantity'] = quantity.toString();
      request.fields['unit'] = unit;
      request.fields['quality'] = quality;
      request.fields['harvestDate'] = harvestDate.toIso8601String();
      request.fields['notes'] = notes;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      debugPrint('Đang gửi dữ liệu thu hoạch (Submitting harvest) đến: $uri');
      var response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Ghi nhận thu hoạch thành công!');
        return true;
      } else {
        debugPrint('Lỗi server: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Ngoại lệ khi gửi thu hoạch: $e');
      throw Exception('Lỗi mạng hoặc server. Vui lòng thử lại.');
    }
  }
}

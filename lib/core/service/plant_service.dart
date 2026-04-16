import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class PlantService {
  /// Gọi API AI để phân tích bệnh của cây trồng dựa trên hình ảnh
  static Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    try {
      final response = await ApiClient.instance.postMultipart(
        '/api/Plant/analyze',
        files: [imageFile],
        fileField: 'Image',
      );
      
      if (response != null && response is Map<String, dynamic>) {
         return response;
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Lỗi phân tích hình ảnh AI: $e');
      }
      rethrow;
    }
  }
}
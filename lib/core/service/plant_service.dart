import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class PlantService {
  /// Gọi API AI để phân tích bệnh của cây trồng dựa trên hình ảnh
  static Future<Map<String, dynamic>> analyzePlant(File imageFile) async {
    try {
      // Chuyển hướng sang AIService để đồng bộ format dữ liệu chuẩn cho UI
      return await AIService.analyzePlantImage(imageFile);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Lỗi phân tích hình ảnh AI: $e');
      }
      rethrow;
    }
  }
}

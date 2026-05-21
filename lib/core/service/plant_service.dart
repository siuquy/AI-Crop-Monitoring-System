import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class PlantService {
  /// Gọi API AI để phân tích bệnh của cây trồng dựa trên hình ảnh
  static Future<Map<String, dynamic>> analyzePlant(
    File imageFile, {
    String? plantName,
    String? farmId,
    String? plotId,
    String? bedId,
    String? growthStage,
  }) async {
    try {
      return await AIService.analyzePlantImage(
        imageFile,
        plantName: plantName,
        farmId: farmId,
        plotId: plotId,
        bedId: bedId,
        growthStage: growthStage,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Lỗi phân tích hình ảnh AI: $e');
      }
      rethrow;
    }
  }
}

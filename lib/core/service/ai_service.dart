import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AIService {
  AIService._();

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AIService] $message');
    }
  }

  static Future<Map<String, dynamic>> analyzePlantImage(File image) async {
    try {
      final apiClient = ApiClient.instance;

      final response = await apiClient.postMultipart(
        '/api/Plant/analyze',
        files: [image],
        fileField: 'Image',
      );

      if (response != null && response is Map<String, dynamic>) {
        // Dự phòng các trường hợp Backend trả về key khác nhau
        final disease = response["diseaseName"] ??
            response["possibleDisease"] ??
            response["disease"];
        final symptoms =
            response["symptoms"] ?? response["symptomsDetected"] ?? [];
        final treatment = response["treatment"] ??
            response["careSuggestions"] ??
            response["treatmentSuggestions"] ??
            [];

        return {
          "isHealthy": response["isPlant"] == true &&
              (response["severity"] == "none" ||
                  disease == null ||
                  disease == "Khỏe mạnh"),
          "diseaseName": disease ?? "Không phát hiện bệnh",
          "confidence": response["confidence"] ?? 0.0,
          "description": response["description"] ?? "",
          "symptoms": symptoms,
          "treatment": treatment,
          "isPlant": response["isPlant"],
          "plantPart": response["plantPart"],
          "severity": response["severity"],
          "warning": response["warning"],
          "needsMoreImages": response["needsMoreImages"],
        };
      }
      return {};
    } catch (e) {
      _log('Lỗi gọi API phân tích hình ảnh từ Backend: $e');
      throw Exception('Không thể phân tích ảnh qua AI: $e');
    }
  }

  static Future<Map<String, dynamic>> generateDescriptionForPlant(
      String plantName) async {
    _log('generateDescriptionForPlant gọi vào nhưng đã tắt AI trực tiếp');
    throw UnimplementedError(
        'Backend hiện chưa hỗ trợ API sinh mô tả riêng lẻ.');
  }
}

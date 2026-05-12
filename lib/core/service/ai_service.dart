import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AIService {
  AIService._();

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AIService] $message');
    }
  }

  static Future<Map<String, dynamic>> analyzePlantImage(
    File image, {
    String? plantName,
    String? farmId,
    String? plotId,
    String? bedId,
    String? growthStage,
  }) async {
    try {
      final apiClient = ApiClient.instance;

      final Map<String, String> fields = {};
      if (plantName != null) fields['PlantName'] = plantName;
      if (farmId != null) fields['FarmId'] = farmId;
      if (plotId != null) fields['PlotId'] = plotId;
      if (bedId != null) fields['BedId'] = bedId;
      if (growthStage != null) fields['GrowthStage'] = growthStage;

      final response = await apiClient.postMultipart(
        '/api/Plant/analyze',
        fields: fields.isNotEmpty ? fields : null,
        files: [image],
        fileField: 'Image',
      );

      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return {};
    } catch (e) {
      _log('Lỗi gọi API phân tích hình ảnh từ Backend: $e');

      final errorString = e.toString();

      if (errorString.contains('401')) {
        throw Exception('Hết phiên đăng nhập, vui lòng đăng nhập lại.');
      }
      if (errorString.contains('503') ||
          errorString.toLowerCase().contains('quá tải') ||
          errorString.toLowerCase().contains('overloaded')) {
        throw Exception('AI đang quá tải, vui lòng thử lại sau.');
      }

      if (errorString.contains('Parse Gemini JSON lỗi. Raw:')) {
        try {
          final rawStartIndex = errorString.indexOf('Raw: ') + 5;
          final errorEndIndex = errorString.indexOf('. Error:');

          if (rawStartIndex != -1 &&
              errorEndIndex != -1 &&
              rawStartIndex < errorEndIndex) {
            String partialJson =
                errorString.substring(rawStartIndex, errorEndIndex).trim();

            int quoteCount = 0;
            for (int i = 0; i < partialJson.length; i++) {
              if (partialJson[i] == '"' &&
                  (i == 0 || partialJson[i - 1] != '\\')) {
                quoteCount++;
              }
            }

            if (quoteCount % 2 != 0) {
              partialJson += '"';
            }

            int openBrackets = '['.allMatches(partialJson).length;
            int closeBrackets = ']'.allMatches(partialJson).length;
            for (int i = 0; i < openBrackets - closeBrackets; i++) {
              partialJson += ']';
            }

            int openBraces = '{'.allMatches(partialJson).length;
            int closeBraces = '}'.allMatches(partialJson).length;
            for (int i = 0; i < openBraces - closeBraces; i++) {
              partialJson += '}';
            }

            final fixedData = jsonDecode(partialJson) as Map<String, dynamic>;
            _log('Đã tự sửa JSON thành công: $fixedData');

            return {
              "disease": fixedData["possibleDisease"] ??
                  fixedData["disease"] ??
                  "Không rõ",
              "confidence": fixedData["confidence"] ?? 0.0,
              "description": fixedData["description"] ?? "",
              "severity": fixedData["severity"] ?? "none",
              "symptoms": fixedData["symptoms"] ?? [],
              "solutions":
                  fixedData["solutions"] ?? fixedData["treatment"] ?? [],
              "treatmentSteps": fixedData["treatmentSteps"] ?? [],
              "weatherDataUsed": fixedData["weatherDataUsed"],
              "iotDataUsed": fixedData["iotDataUsed"],
              "contextUsed": fixedData["contextUsed"],
            };
          }
        } catch (parseError) {
          _log('Không thể tự sửa JSON: $parseError');
        }
      }

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

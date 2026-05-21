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

      final Map<String, String> fields = {
        'Language': 'vi',
        'Lang': 'vi',
        'ResponseLanguage': 'vi',
        'Prompt':
            'Phân tích ảnh cây trồng. Trả kết quả 100% bằng tiếng Việt. Không dùng tiếng Anh trong disease, description, symptoms, solutions, treatmentSteps, severity.',
      };

      if (plantName != null && plantName.trim().isNotEmpty) {
        fields['PlantName'] = plantName.trim();
      }
      if (farmId != null) fields['FarmId'] = farmId;
      if (plotId != null) fields['PlotId'] = plotId;
      if (bedId != null) fields['BedId'] = bedId;
      if (growthStage != null && growthStage.trim().isNotEmpty) {
        fields['GrowthStage'] = growthStage.trim();
      }

      final response = await apiClient.postMultipart(
        '/api/Plant/analyze',
        fields: fields,
        files: [image],
        fileField: 'Image',
      );

      if (response != null && response is Map<String, dynamic>) {
        return _normalizeVietnameseResponse(response);
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
            return _normalizeVietnameseResponse(fixedData);
          }
        } catch (parseError) {
          _log('Không thể tự sửa JSON: $parseError');
        }
      }

      throw Exception('Không thể phân tích ảnh qua AI: $e');
    }
  }

  static Map<String, dynamic> _normalizeVietnameseResponse(
      Map<String, dynamic> data) {
    final raw = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;

    final disease = raw['disease'] ??
        raw['possibleDisease'] ??
        raw['plantDisease'] ??
        raw['diseaseName'] ??
        'Không rõ';

    final confidence = _normalizeConfidence(raw['confidence']);

    final description = raw['description'] ??
        raw['desc'] ??
        raw['detail'] ??
        'Không có mô tả chi tiết.';

    final severity = raw['severity'] ?? raw['riskLevel'] ?? 'none';

    final symptoms = _toStringList(
      raw['symptoms'] ?? raw['symptomsDetected'] ?? raw['signs'],
    );

    final solutions = _toStringList(
      raw['solutions'] ?? raw['careSuggestions'] ?? raw['recommendations'],
    );

    final treatmentSteps = _toStringList(
      raw['treatmentSteps'] ?? raw['treatment'] ?? raw['actions'],
    );

    return {
      ...raw,
      'disease': _toVietnamese(disease.toString()),
      'confidence': confidence,
      'description': _toVietnamese(description.toString()),
      'severity': _toVietnameseSeverity(severity.toString()),
      'symptoms': symptoms.map(_toVietnamese).toList(),
      'solutions': solutions.map(_toVietnamese).toList(),
      'treatmentSteps': treatmentSteps.map(_toVietnamese).toList(),
      'weatherDataUsed': raw['weatherDataUsed'],
      'iotDataUsed': raw['iotDataUsed'],
      'contextUsed': raw['contextUsed'],
    };
  }

  static double _normalizeConfidence(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      final v = value.toDouble();
      if (v > 1) return v / 100;
      return v;
    }

    final parsed = double.tryParse(value.toString().replaceAll('%', '').trim());
    if (parsed == null) return 0.0;
    if (parsed > 1) return parsed / 100;
    return parsed;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'\n|;|\|'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  static String _toVietnameseSeverity(String text) {
    final value = text.trim().toLowerCase();

    switch (value) {
      case 'none':
      case 'healthy':
      case 'normal':
      case 'no disease':
        return 'Không có';
      case 'low':
      case 'mild':
      case 'minor':
        return 'Nhẹ';
      case 'medium':
      case 'moderate':
        return 'Trung bình';
      case 'high':
      case 'severe':
      case 'critical':
        return 'Nặng';
      default:
        return _toVietnamese(text);
    }
  }

  static String _toVietnamese(String text) {
    String result = text.trim();

    final Map<String, String> dictionary = {
      'Healthy': 'Khỏe mạnh',
      'healthy': 'khỏe mạnh',
      'Unknown': 'Không xác định',
      'unknown': 'không xác định',
      'No disease detected': 'Không phát hiện bệnh',
      'Disease detected': 'Phát hiện bệnh',
      'Leaf spot': 'Bệnh đốm lá',
      'Powdery mildew': 'Bệnh phấn trắng',
      'Downy mildew': 'Bệnh sương mai',
      'Blight': 'Bệnh cháy lá',
      'Early blight': 'Bệnh cháy lá sớm',
      'Late blight': 'Bệnh cháy lá muộn',
      'Rust': 'Bệnh gỉ sắt',
      'Root rot': 'Bệnh thối rễ',
      'Anthracnose': 'Bệnh thán thư',
      'Bacterial wilt': 'Bệnh héo xanh vi khuẩn',
      'Yellowing leaves': 'Lá bị vàng',
      'brown spots': 'đốm nâu',
      'yellow spots': 'đốm vàng',
      'white powder': 'lớp phấn trắng',
      'wilting': 'héo lá',
      'leaf curling': 'xoăn lá',
      'fungal infection': 'nhiễm nấm',
      'bacterial infection': 'nhiễm vi khuẩn',
      'viral infection': 'nhiễm virus',
      'Apply fungicide': 'Sử dụng thuốc trừ nấm',
      'Apply pesticide': 'Sử dụng thuốc bảo vệ thực vật',
      'Remove infected leaves': 'Loại bỏ lá bị nhiễm bệnh',
      'Improve air circulation': 'Cải thiện độ thông thoáng',
      'Avoid overhead watering': 'Tránh tưới nước trực tiếp lên lá',
      'Monitor the plant': 'Theo dõi cây trồng',
      'Consult an agricultural specialist':
          'Tham khảo ý kiến chuyên gia nông nghiệp',
      'Low': 'Thấp',
      'Medium': 'Trung bình',
      'High': 'Cao',
      'Severe': 'Nặng',
      'Mild': 'Nhẹ',
      'Moderate': 'Trung bình',
    };

    dictionary.forEach((en, vi) {
      result = result.replaceAll(en, vi);
    });

    return result;
  }

  static Future<Map<String, dynamic>> generateDescriptionForPlant(
      String plantName) async {
    _log('generateDescriptionForPlant gọi vào nhưng đã tắt AI trực tiếp');
    throw UnimplementedError(
        'Backend hiện chưa hỗ trợ API sinh mô tả riêng lẻ.');
  }
}

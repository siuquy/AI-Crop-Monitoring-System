import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
// Yêu cầu cài đặt: flutter pub add google_generative_ai
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  AIService._();

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AIService] $message');
    }
  }

  // Gọi API Gemini thật để phân tích ảnh cây trồng.
  static Future<Map<String, dynamic>> analyzePlantImage(File image) async {
    try {
      const String apiKey = 'AIzaSyBrdl4633QOVweN2-aIk2GUoUfmt0bmDT8';

      if (apiKey == 'AIzaSyBrdl4633QOVweN2-aIk2GUoUfmt0bmDT8') {
        _log('LƯU Ý: Vui lòng cấu hình API Key cho Gemini!');
      }

      final model = GenerativeModel(
        model:
            'gemini-2.0-flash', // Đã nâng cấp lên model AI mới nhất của Google
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final imageBytes = await image.readAsBytes();
      final prompt = TextPart('''
Bạn là một chuyên gia nông nghiệp. Phân tích ảnh này và BẮT BUỘC trả về ĐÚNG định dạng JSON sau (key tiếng Anh, value tiếng Việt):
{
  "isHealthy": false,
  "diseaseName": "Tên bệnh bằng tiếng Việt hoặc 'Khỏe mạnh'",
  "confidence": 0.95,
  "description": "BẮT BUỘC ĐIỀN: Phân tích chi tiết những gì bạn thấy trong ảnh (màu sắc, đốm, lá héo...)",
  "symptoms": ["Triệu chứng 1", "Triệu chứng 2"],
  "treatment": ["Cách xử lý 1", "Cách xử lý 2"]
}
Lưu ý: Tuyệt đối không được để trống trường "description", "symptoms" hay "treatment". Nếu cây khỏe mạnh, hãy mô tả sự khỏe mạnh đó.
''');

      String mimeType = 'image/jpeg';
      final pathLower = image.path.toLowerCase();
      if (pathLower.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (pathLower.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (pathLower.endsWith('.heic') || pathLower.endsWith('.heif')) {
        mimeType = 'image/heic';
      }

      final imagePart = DataPart(mimeType, imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final responseText = response.text;
      if (responseText != null) {
        String cleanJson =
            responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } else {
        throw Exception('Không nhận được kết quả từ AI.');
      }
    } catch (e) {
      _log('Lỗi phân tích hình ảnh AI: $e');
      throw Exception('Lỗi khi gọi AI: $e');
    }
  }
}

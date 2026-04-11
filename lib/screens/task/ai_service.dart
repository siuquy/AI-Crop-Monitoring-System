import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  AIService._();

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AIService] $message');
    }
  }

  static Future<Map<String, dynamic>> analyzePlantImage(File image) async {
    try {
      const String apiKey = 'AIzaSyBrdl4633QOVweN2-aIk2GUoUfmt0bmDT8';

      if (apiKey == 'AIzaSyBrdl4633QOVweN2-aIk2GUoUfmt0bmDT8') {
        _log('LƯU Ý: Vui lòng cấu hình API Key cho Gemini!');
      }

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
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
      if (e.toString().contains('Quota exceeded') ||
          e.toString().contains('rate limits')) {
        throw Exception(
            'Hệ thống AI đang quá tải hoặc hết lượt phân tích. Vui lòng đợi khoảng 1 phút và thử lại.');
      }
      throw Exception('Lỗi khi gọi AI: $e');
    }
  }

  /// Hàm này dùng để sinh mô tả chi tiết bằng văn bản (không cần gửi ảnh)
  /// cho các kết quả trả về từ PlantNet API (vốn chỉ có tên).
  static Future<Map<String, dynamic>> generateDescriptionForPlant(
      String plantName) async {
    try {
      const String apiKey = 'AIzaSyBrdl4633QOVweN2-aIk2GUoUfmt0bmDT8';
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final promptStr = '''
Bạn là chuyên gia nông nghiệp. Một hệ thống vừa nhận diện được cây trồng hoặc bệnh có tên là "$plantName".
Hãy cung cấp thông tin chi tiết bằng tiếng Việt và BẮT BUỘC trả về ĐÚNG định dạng JSON sau:
{
  "description": "Mô tả chi tiết về loại cây hoặc bệnh này.",
  "symptoms": ["Dấu hiệu nhận biết 1", "Dấu hiệu nhận biết 2"],
  "treatment": ["Cách chăm sóc hoặc xử lý 1", "Cách chăm sóc hoặc xử lý 2"]
}
''';

      final response = await model.generateContent([Content.text(promptStr)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
    } catch (e) {
      _log('Lỗi sinh mô tả bằng văn bản: $e');
    }
    return {}; // Trả về object rỗng nếu lỗi, để không làm gián đoạn luồng chính
  }
}

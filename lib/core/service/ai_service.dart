import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  AIService._();

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AIService] $message');
    }
  }

  static Future<Map<String, dynamic>> analyzePlantImage(File image) async {
    try {
      final String apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();

      if (apiKey.isEmpty) {
        throw Exception('Thiếu GEMINI_API_KEY trong file .env');
      }

      final model = GenerativeModel(
        model:
            'gemini-1.5-flash', // Vẫn phải giữ bản 1.5 cho ảnh vì bản Pro đời đầu không đọc được ảnh
        apiKey: apiKey,
      );

      final imageBytes = await image.readAsBytes();
      final prompt = TextPart(
          '''Bạn là chuyên gia bệnh học thực vật (plant pathology expert).

Hãy phân tích kỹ hình ảnh cây trồng được cung cấp.

Yêu cầu phân tích:
- Quan sát kỹ lá/thân/cành
- Mô tả chi tiết các dấu hiệu bất thường (đốm, vàng lá, héo, nấm, cháy lá, lỗ thủng...)
- Đưa ra tên bệnh có khả năng cao nhất (nếu có)
- Đánh giá mức độ chắc chắn (confidence từ 0 đến 1)
- Đề xuất cách xử lý thực tế, dễ áp dụng

QUY TẮC BẮT BUỘC:
- Chỉ trả về JSON hợp lệ
- Không markdown (không dùng ```json)
- Không giải thích thêm ngoài JSON
- Không được để trống bất kỳ field nào
- Nếu cây khỏe mạnh → isHealthy = true và diseaseName = "Khỏe mạnh"

Định dạng JSON:
{
  "isHealthy": false,
  "diseaseName": "Tên bệnh bằng tiếng Việt hoặc 'Khỏe mạnh'",
  "confidence": 0.85,
  "description": "Mô tả chi tiết những gì quan sát được trên cây",
  "symptoms": ["Triệu chứng 1", "Triệu chứng 2"],
  "treatment": ["Cách xử lý 1", "Cách xử lý 2"]
}

Nếu không chắc chắn, vẫn phải đưa ra dự đoán hợp lý nhất và giảm confidence.''');

      final response = await model.generateContent([
        Content.multi([
          prompt,
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final text = response.text ?? '{}';
      String cleanJson =
          text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      _log('Lỗi phân tích hình ảnh AI: $e');
      throw Exception(
          'API Key của bạn không hỗ trợ phân tích ảnh (Lỗi: $e). Vui lòng quét ảnh rõ nét hơn để PlantNet nhận diện.');
    }
  }

  static Future<Map<String, dynamic>> generateDescriptionForPlant(
      String plantName) async {
    try {
      final String apiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim();

      if (apiKey.isEmpty) {
        throw Exception('Thiếu GEMINI_API_KEY');
      }

      final model = GenerativeModel(
        model:
            'gemini-pro', // Đổi sang gemini-pro để đảm bảo 100% chạy thành công khi sinh văn bản
        apiKey: apiKey,
      );

      final promptStr = '''Bạn là chuyên gia nông nghiệp.

Hệ thống đã nhận diện được cây hoặc bệnh có tên: "$plantName".

Hãy cung cấp thông tin chi tiết.

QUY TẮC:
- Chỉ trả về JSON hợp lệ
- Không markdown
- Không giải thích thêm

Định dạng JSON:
{
  "description": "Mô tả chi tiết về cây hoặc bệnh",
  "symptoms": ["Dấu hiệu 1", "Dấu hiệu 2"],
  "treatment": ["Cách xử lý 1", "Cách xử lý 2"]
}''';

      final response = await model.generateContent([Content.text(promptStr)]);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
    } catch (e) {
      _log('Lỗi sinh mô tả: $e');
      throw Exception('Lỗi khi gọi AI: $e');
    }
    return {};
  }
}

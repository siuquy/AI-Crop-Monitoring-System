import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class AIService {
  AIService._();

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AIService] $message');
    }
  }

  // Simulates calling a backend that uses Gemini to analyze a plant image.
  static Future<Map<String, dynamic>> analyzePlantImage(File image) async {
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 3));

    // Simulate a random success or failure
    final random = Random();
    if (random.nextDouble() < 0.1) {
      // 10% chance of failure
      throw Exception('Không thể kết nối đến máy chủ AI. Vui lòng thử lại.');
    }

    // Simulate a healthy plant 30% of the time
    if (random.nextDouble() < 0.3) {
      return {
        'diseaseName': 'Khỏe mạnh',
        'confidence': 0.98,
        'description':
            'Không phát hiện dấu hiệu bệnh tật. Cây trồng đang phát triển tốt.',
        'symptoms': [],
        'treatment': [],
        'isHealthy': true,
      };
    }

    // Return mock analysis data for a sick plant
    return {
      'diseaseName': 'Bệnh đốm lá cà chua',
      'confidence': 0.92, // 92%
      'description':
          'Bệnh đốm lá (Septoria lycopersici) là một trong những bệnh phổ biến nhất trên cây cà chua. Bệnh gây ra bởi nấm và thường xuất hiện ở các lá phía dưới trước tiên, sau đó lan dần lên trên.',
      'symptoms': [
        'Xuất hiện các đốm nhỏ, tròn, có màu xám hoặc nâu ở giữa và viền sẫm màu.',
        'Các đốm có thể hợp nhất thành các mảng lớn, khiến lá bị vàng và rụng sớm.',
        'Bệnh nặng có thể làm cây còi cọc, giảm năng suất và chất lượng quả.'
      ],
      'treatment': [
        'Cắt tỉa và tiêu hủy các lá bị bệnh để giảm nguồn lây lan.',
        'Sử dụng các loại thuốc diệt nấm có chứa hoạt chất mancozeb, chlorothalonil hoặc đồng.',
        'Luân canh cây trồng, không trồng cà chua ở cùng một vị trí trong ít nhất 2-3 năm.'
      ],
      'isHealthy': false,
    };
  }

  // Simulates
}

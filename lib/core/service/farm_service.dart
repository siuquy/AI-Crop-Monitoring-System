import 'api_client.dart';
import 'package:flutter/foundation.dart';

class FarmService {
  static Future<Map<String, String>> getFarmMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Farms');
      final map = <String, String>{};

      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        for (var item in data) {
          // Cập nhật lấy theo key 'id' và 'name' nếu API thay đổi
          final id = item['farmId']?.toString() ?? item['id']?.toString();
          final name = item['farmName']?.toString() ?? item['name']?.toString();
          if (id != null && name != null) {
            map[id] = name;
          }
        }
      }
      return map;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi tải danh sách Farm: $e');
      return {};
    }
  }
}

import 'api_client.dart';
import 'package:flutter/foundation.dart';

class BedService {
  static Future<Map<String, Map<String, dynamic>>> getBedMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Beds');
      final map = <String, Map<String, dynamic>>{};

      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        for (var item in data) {
          final id = item['bedId']?.toString() ?? item['id']?.toString();
          if (id != null) {
            map[id] = item as Map<String, dynamic>;
          }
        }
      }
      return map;
    } catch (e) {
      if (kDebugMode) debugPrint('Lỗi tải danh sách Bed: $e');
      return {};
    }
  }
}

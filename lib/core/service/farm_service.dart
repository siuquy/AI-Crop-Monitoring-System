import 'api_client.dart';

class FarmService {
  static Future<Map<String, String>> getFarmMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Farms');
      final map = <String, String>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          final id = item['farmId']?.toString();
          final name = item['farmName']?.toString();
          if (id != null && name != null) {
            map[id] = name;
          }
        }
      }
      return map;
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách Nông trại (Farms): $e');
    }
  }
}

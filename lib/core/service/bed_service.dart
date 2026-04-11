import 'api_client.dart';

class BedService {
  static Future<Map<String, Map<String, dynamic>>> getBedMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Beds');
      final map = <String, Map<String, dynamic>>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          final id = item['bedId']?.toString();
          if (id != null) {
            map[id] = {
              'bedName': item['bedName']?.toString() ?? 'Không rõ',
              'plotId': item['plotId']?.toString(),
            };
          }
        }
      }
      return map;
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách Luống (Beds): $e');
    }
  }
}

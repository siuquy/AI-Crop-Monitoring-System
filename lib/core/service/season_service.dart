import 'api_client.dart';

class SeasonService {
  /// Lấy danh sách Mùa vụ (Seasons) và map theo ID để dễ truy xuất
  static Future<Map<String, Map<String, dynamic>>> getSeasonMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Seasons');
      final map = <String, Map<String, dynamic>>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          final id = item['seasonId']?.toString();
          if (id != null) {
            map[id] = item as Map<String, dynamic>;
          }
        }
      }
      return map;
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách Mùa vụ (Seasons): $e');
    }
  }
}

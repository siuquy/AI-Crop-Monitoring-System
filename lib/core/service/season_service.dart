import 'api_client.dart';

class SeasonService {
  static Future<Map<String, Map<String, dynamic>>> getSeasonMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Seasons');
      final map = <String, Map<String, dynamic>>{};

      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        for (var item in data) {
          final id = item['seasonId']?.toString();
          if (id != null) {
            map[id] = item as Map<String, dynamic>;
          }
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }
}

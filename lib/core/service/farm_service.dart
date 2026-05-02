import 'api_client.dart';

class FarmService {
  static Future<Map<String, String>> getFarmMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Farms');
      final map = <String, String>{};

      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        for (var item in data) {
          final id = item['farmId']?.toString();
          final name = item['farmName']?.toString();
          if (id != null && name != null) {
            map[id] = name;
          }
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }
}

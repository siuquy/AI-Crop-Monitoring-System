import 'api_client.dart';

class FarmService {
  static Future<Map<String, String>> getFarmMap() async {
    final response = await ApiClient.instance.get('/api/Farms');
    final Map<String, String> map = {};

    if (response['success'] == true && response['data'] != null) {
      for (var item in response['data']) {
        final id = item['farmId']?.toString();
        final name = item['farmName']?.toString();
        if (id != null && name != null) map[id] = name;
      }
    }
    return map;
  }
}

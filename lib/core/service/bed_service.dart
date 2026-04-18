import 'api_client.dart';

class BedService {
  static Future<Map<String, Map<String, dynamic>>> getBedMap() async {
    final response = await ApiClient.instance.get('/api/Beds');
    final Map<String, Map<String, dynamic>> map = {};

    if (response['success'] == true && response['data'] != null) {
      for (var item in response['data']) {
        final id = item['bedId']?.toString();
        if (id != null) {
          map[id] = {
            'bedName': item['bedName'],
            'plotId': item['plotId'],
          };
        }
      }
    }
    return map;
  }
}

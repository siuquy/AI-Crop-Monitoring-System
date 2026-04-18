import 'api_client.dart';

class SeasonDetailService {
  static Future<Map<String, Map<String, dynamic>>> getSeasonDetailMap() async {
    final response = await ApiClient.instance.get('/api/seasons-details');
    final Map<String, Map<String, dynamic>> map = {};

    if (response['success'] == true && response['data'] != null) {
      for (var item in response['data']) {
        final id = item['seasonDetailId']?.toString();
        if (id != null) {
          map[id] = {
            'seasonId': item['seasonId'],
            'bedId': item['bedId'],
            'cropName': item['cropName'],
            'seasonName': item['seasonName'],
          };
        }
      }
    }
    return map;
  }
}

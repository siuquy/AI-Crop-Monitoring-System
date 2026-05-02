import 'api_client.dart';

class HarvestService {
  static Future<List<dynamic>> getHarvests() async {
    try {
      final response = await ApiClient.instance.get('/api/harvests');
      if (response != null && response['success'] == true) {
        return response['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSeasonToHarvestMap() async {
    final harvests = await getHarvests();
    final map = <String, dynamic>{};
    for (var harvest in harvests) {
      if (harvest['seasonId'] != null) {
        map[harvest['seasonId'].toString().toLowerCase()] = harvest;
      }
    }
    return map;
  }
}

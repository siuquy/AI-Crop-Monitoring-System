import 'api_client.dart';

class SeasonService {
  static Future<List<dynamic>> getSeasons() async {
    try {
      final response = await ApiClient.instance.get('/api/Seasons');
      if (response != null && response['success'] == true) {
        return response['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

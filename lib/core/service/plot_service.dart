import 'api_client.dart';

class PlotService {
  static Future<Map<String, Map<String, dynamic>>> getPlotMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Plots');
      final map = <String, Map<String, dynamic>>{};
      
      if (response != null && response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        for (var item in data) {
          final id = item['plotId']?.toString();
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

import 'api_client.dart';

class PlotService {
  static Future<Map<String, Map<String, dynamic>>> getPlotMap() async {
    final response = await ApiClient.instance.get('/api/Plots');
    final Map<String, Map<String, dynamic>> map = {};

    if (response['success'] == true && response['data'] != null) {
      for (var item in response['data']) {
        final id = item['plotId']?.toString();
        if (id != null) {
          map[id] = {
            'plotName': item['plotName'],
            'farmId': item['farmId'],
          };
        }
      }
    }
    return map;
  }
}

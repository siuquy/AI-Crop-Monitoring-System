import 'api_client.dart';

class PlotService {
  static Future<Map<String, Map<String, dynamic>>> getPlotMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Plots');
      final map = <String, Map<String, dynamic>>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          final id = item['plotId']?.toString();
          if (id != null) {
            map[id] = {
              'plotName': item['plotName']?.toString() ?? 'Không rõ',
              'farmId': item['farmId']?.toString(),
            };
          }
        }
      }
      return map;
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách Thửa (Plots): $e');
    }
  }
}

import 'api_client.dart';

class CropService {
  static Future<Map<String, String>> getCropMap() async {
    try {
      final response = await ApiClient.instance.get('/api/Crops');
      final map = <String, String>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          final id = item['cropId']?.toString();
          final name = item['cropName']?.toString();
          if (id != null && name != null) {
            map[id] = name;
          }
        }
      }
      return map;
    } catch (e) {
      throw ApiException('Lỗi khi tải danh sách Cây trồng (Crops): $e');
    }
  }
}

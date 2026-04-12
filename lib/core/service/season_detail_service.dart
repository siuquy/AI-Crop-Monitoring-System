import 'api_client.dart';

class SeasonDetailService {
  static Future<Map<String, Map<String, dynamic>>> getSeasonDetailMap() async {
    try {
      final response = await ApiClient.instance.get('/api/seasons-details');
      final map = <String, Map<String, dynamic>>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          if (item is Map) {
            final key = item['seasonDetailId']?.toString() ??
                item['seasonId']?.toString();
            if (key != null) {
              map[key] = Map<String, dynamic>.from(item);
            }
          }
        }
      }
      return map;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi khi tải chi tiết Mùa vụ (SeasonDetails): $e');
    }
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
      getSeasonDetailsGroupedBySeasonId() async {
    try {
      final response = await ApiClient.instance.get('/api/seasons-details');
      final map = <String, List<Map<String, dynamic>>>{};

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        for (var item in response['data']) {
          if (item is Map) {
            final seasonId = item['seasonId']?.toString();
            if (seasonId != null) {
              map
                  .putIfAbsent(seasonId, () => [])
                  .add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
      return map;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Lỗi khi tải chi tiết Mùa vụ (SeasonDetails): $e');
    }
  }
}

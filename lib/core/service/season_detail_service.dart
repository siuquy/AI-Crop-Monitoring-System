import 'package:flutter/foundation.dart';
import 'api_client.dart';

class SeasonDetailService {
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[SeasonDetailService] $message');
    }
  }

  static Future<Map<String, dynamic>> getSeasonDetailMap() async {
    try {
      final json = await ApiClient.instance.get('/api/seasons-details');
      final data = json['data'];

      return {for (var sd in data) sd['seasonId']: sd};
    } on ApiException catch (e) {
      _log('API Error fetching season details: $e');
      rethrow;
    } catch (e) {
      _log('Unexpected error fetching season details: $e');
      // Re-throw as a standard exception type so the UI can handle it.
      throw ApiException('Lỗi không xác định khi tải dữ liệu mùa vụ.');
    }
  }
}

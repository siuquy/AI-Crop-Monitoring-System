import 'package:acmms/core/service/api_client.dart';
import 'package:acmms/models/growth_tracking.dart';
import 'package:flutter/foundation.dart';

class GrowthTrackingService {
  GrowthTrackingService._();

  static Future<List<GrowthTracking>> getGrowthTrackings() async {
    try {
      final apiClient = ApiClient.instance;
      final response = await apiClient.get('/api/growth-trackings');

      if (response != null &&
          response['success'] == true &&
          response['data'] is List) {
        final List<dynamic> data = response['data'];
        return data.map((json) => GrowthTracking.fromJson(json)).toList();
      } else {
        debugPrint(
            'GrowthTrackingService: Invalid response format or success is false.');
        return [];
      }
    } on ApiException catch (e) {
      debugPrint('GrowthTrackingService: API Error - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('GrowthTrackingService: Unexpected error - $e');
      rethrow;
    }
  }
}

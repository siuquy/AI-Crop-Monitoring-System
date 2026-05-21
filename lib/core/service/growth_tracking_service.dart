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

  static Future<GrowthTracking?> createGrowthTracking({
    required String harvestDetailId,
    required String stageId,
    required DateTime startDate,
    required String healthStatus,
    required double actualHeight,
    required String notes,
  }) async {
    try {
      final apiClient = ApiClient.instance;
      final Map<String, dynamic> body = {
        'harvestDetailId': harvestDetailId,
        'stageId': stageId,
        'startDate': startDate
            .toIso8601String(), // Cấu trúc thời gian ISO 8601 để gửi lên Backend
        'healthStatus': healthStatus,
        'actualHeight': actualHeight,
        'notes': notes,
      };

      final response =
          await apiClient.post('/api/growth-trackings', body: body);

      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        return GrowthTracking.fromJson(
            response['data'] as Map<String, dynamic>);
      }
      return null;
    } on ApiException catch (e) {
      debugPrint('GrowthTrackingService: API Error on create - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('GrowthTrackingService: Unexpected error on create - $e');
      rethrow;
    }
  }

  static Future<GrowthTracking?> updateGrowthTracking({
    required String trackingId,
    required String trackingStatus,
    required String healthStatus,
    required double actualHeight,
    required String notes,
    double actualYield = 0,
    int delayDays = 0,
    String delayReason = "string",
  }) async {
    try {
      final apiClient = ApiClient.instance;
      final Map<String, dynamic> body = {
        'trackingStatus': trackingStatus,
        'healthStatus': healthStatus,
        'actualHeight': actualHeight,
        'actualYield': actualYield,
        'delayDays': delayDays,
        'delayReason': delayReason,
        'lastObservedAt': DateTime.now().toIso8601String(),
        'notes': notes,
      };

      final response =
          await apiClient.put('/api/growth-trackings/$trackingId', body: body);

      if (response != null &&
          response['success'] == true &&
          response['data'] != null) {
        return GrowthTracking.fromJson(
            response['data'] as Map<String, dynamic>);
      }
      return null;
    } on ApiException catch (e) {
      debugPrint('GrowthTrackingService: API Error on update - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('GrowthTrackingService: Unexpected error on update - $e');
      rethrow;
    }
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class PlotService {
  PlotService._();

  static Map<String, Map<String, dynamic>>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PlotService] $message');
    }
  }

  static Future<Map<String, Map<String, dynamic>>> getPlotMap(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Returning cached plots (${_cache!.length})');
      return _cache!;
    }

    try {
      final json = await ApiClient.instance.get('/api/Plots');
      final list = json['data'] as List;

      final plotMap = {
        for (var item in list)
          if (item['plotId'] != null)
            item['plotId'].toString(): {
              'plotName': item['plotName'],
              'farmId': item['farmId'], // Crucial for linking to a farm
            }
      };

      _cache = plotMap;
      _cacheTime = DateTime.now();
      _log('Fetched and cached ${plotMap.length} plots.');
      return plotMap;
    } on ApiException catch (e) {
      _log('API Error fetching plots: $e');
      rethrow;
    } catch (e) {
      _log('Unexpected error fetching plots: $e');
      throw ApiException('Lỗi không xác định khi tải dữ liệu khu vực.');
    }
  }
}

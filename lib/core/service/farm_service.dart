import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class FarmService {
  FarmService._();

  static Map<String, String>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FarmService] $message');
    }
  }

  static Future<Map<String, String>> getFarmMap(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Returning cached farms (${_cache!.length})');
      return _cache!;
    }

    try {
      final json = await ApiClient.instance.get('/api/Farms');
      final list = json['data'] as List;

      final farmMap = {
        for (var item in list)
          if (item['farmId'] != null && item['farmName'] != null)
            item['farmId'].toString(): item['farmName'].toString(),
      };

      _cache = farmMap;
      _cacheTime = DateTime.now();
      _log('Fetched and cached ${farmMap.length} farms.');
      return farmMap;
    } on ApiException catch (e) {
      _log('API Error fetching farms: $e');
      rethrow;
    } catch (e) {
      _log('Unexpected error fetching farms: $e');
      throw ApiException('Lỗi không xác định khi tải dữ liệu trang trại.');
    }
  }
}

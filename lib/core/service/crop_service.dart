import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class CropService {
  CropService._();

  static Map<String, String>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[CropService] $message');
    }
  }

  static Future<Map<String, String>> getCropMap(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Returning cached crops (${_cache!.length})');
      return _cache!;
    }

    try {
      final json = await ApiClient.instance.get('/api/Crops');
      final list = json['data'] as List;

      final cropMap = {
        for (var item in list)
          if (item['cropId'] != null && item['cropName'] != null)
            item['cropId'].toString(): item['cropName'].toString(),
      };

      _cache = cropMap;
      _cacheTime = DateTime.now();
      _log('Fetched and cached ${cropMap.length} crops.');
      return cropMap;
    } on ApiException catch (e) {
      _log('API Error fetching crops: $e');
      rethrow;
    } catch (e) {
      _log('Unexpected error fetching crops: $e');
      throw ApiException('Lỗi không xác định khi tải dữ liệu cây trồng.');
    }
  }
}

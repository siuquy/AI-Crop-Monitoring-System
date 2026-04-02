import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class BedService {
  BedService._();

  static Map<String, Map<String, dynamic>>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[BedService] $message');
    }
  }

  static Future<Map<String, Map<String, dynamic>>> getBedMap(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      _log('Returning cached beds (${_cache!.length})');
      return _cache!;
    }

    try {
      final json = await ApiClient.instance.get('/api/Beds');
      final list = json['data'] as List;

      final bedMap = {
        for (var item in list)
          if (item['bedId'] != null)
            item['bedId'].toString(): {
              'bedName': item['bedName'],
              'plotId': item['plotId'],
              'plotName': item['plotName'],
            }
      };

      _cache = bedMap;
      _cacheTime = DateTime.now();
      _log('Fetched and cached ${bedMap.length} beds.');
      return bedMap;
    } on ApiException catch (e) {
      _log('API Error fetching beds: $e');
      rethrow;
    } catch (e) {
      _log('Unexpected error fetching beds: $e');
      throw ApiException('Lỗi không xác định khi tải dữ liệu luống.');
    }
  }
}

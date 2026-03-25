import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'task_service.dart'; // For ApiException

class FarmService {
  FarmService._();

  static const String _baseUrl = 'https://10.0.2.2:7093';
  static const Duration _timeout = Duration(seconds: 8);

  static Map<String, String>? _cache;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FarmService] $message');
    }
  }

  static Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  static Future<http.Response> _get(Uri uri) async {
    _log('GET $uri');
    var response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode == 307 || response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        final newUri = uri.resolve(location);
        _log('Following temporary redirect to $newUri');
        response = await http.get(newUri,
            headers: const {'Accept': 'application/json'}).timeout(_timeout);
      }
    }
    return response;
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

    final uri = _buildUri('/api/Farms');

    try {
      final response = await _get(uri);
      _log('Status: ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException('Yêu cầu thất bại', statusCode: response.statusCode);
      }

      final json = jsonDecode(response.body);
      final list = json['data'] as List;

      final farmMap = {
        for (var item in list)
          item['farmId'].toString(): item['farmName'].toString(),
      };

      _cache = farmMap;
      _cacheTime = DateTime.now();
      return farmMap;
    } on SocketException {
      throw ApiException('Không thể kết nối tới server.');
    } on TimeoutException {
      throw ApiException('Server phản hồi quá lâu.');
    } on FormatException {
      throw ApiException('Phản hồi từ server không đúng định dạng JSON.');
    }
  }
}

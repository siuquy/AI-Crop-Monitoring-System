import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SeasonDetailService {
  static const String baseUrl = "http://10.0.2.2:5298/api";

  static Future<Map<String, dynamic>> getSeasonDetailMap() async {
    try {
      final res = await Dio().get('$baseUrl/seasons-details');

      final data = res.data['data'];

      // Map theo seasonId
      return {for (var sd in data) sd['seasonId']: sd};
    } catch (e) {
      debugPrint('SeasonDetailService ERROR: $e');
      return {}; 
    }
  }
}

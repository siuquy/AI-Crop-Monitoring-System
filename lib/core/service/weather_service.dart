import 'package:flutter/foundation.dart';
import 'api_client.dart';

class WeatherService {
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WeatherService] $message');
    }
  }

  static Future<Map<String, dynamic>> fetchWeather({
    double lat = 10.8231,
    double lng = 106.6297,
  }) async {
    try {
      _log('Đang lấy thời tiết từ Backend cho Lat: $lat, Lon: $lng');

      final data = await ApiClient.instance
          .get('/api/Weather/current?lat=$lat&lng=$lng');

      if (data != null) {
        _log('Dữ liệu thời tiết đã nhận: $data');
        return {
          'temperature': data['tempC'],
          'description': data['condition']['text'],
          'humidity': data['humidity'],
          'windSpeed': data['windKph'] /
              3.6, 
          'icon': 'https:${data['condition']['icon']}',
          'cityName': data['location']['name'],
        };
      } else {
        return Future.error('Không nhận được dữ liệu thời tiết từ hệ thống.');
      }
    } catch (e) {
      _log('Lỗi khi lấy thời tiết: $e');
      return Future.error('Không thể lấy dữ liệu thời tiết: $e');
    }
  }
}

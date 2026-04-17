import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'c36b2784d9dc467082692838261704';
  static const String _baseUrl = 'https://api.weatherapi.com/v1/current.json';

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WeatherService] $message');
    }
  }

  static Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có được bật không.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log('Dịch vụ vị trí bị tắt.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _log('Quyền truy cập vị trí bị từ chối.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _log('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
      return null;
    }

    // Khi quyền được cấp, lấy vị trí hiện tại.
    _log('Đang lấy vị trí hiện tại...');
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Lấy dữ liệu thời tiết dựa trên vị trí hiện tại.
  static Future<Map<String, dynamic>> fetchWeather() async {
    if (_apiKey == 'YOUR_OPENWEATHERMAP_API_KEY' || _apiKey.isEmpty) {
      _log('OpenWeatherMap API Key chưa được cấu hình.');
      return Future.error('OpenWeatherMap API Key chưa được cấu hình.');
    }

    try {
      final position = await _getCurrentLocation();
      final lat = 10.8231;
      final lon = 106.6297;

      _log('Đang lấy thời tiết cho Lat: $lat, Lon: $lon');

      final uri = Uri.parse('$_baseUrl?key=$_apiKey&q=$lat,$lon&lang=vi');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response
            .bodyBytes)); 
        _log('Dữ liệu thời tiết đã nhận: $data');
        return {
          'temperature': data['current']['temp_c'],
          'description': data['current']['condition']['text'],
          'humidity': data['current']['humidity'],
          'windSpeed':
              data['current']['wind_kph'] / 3.6,
          'icon':
              'https:${data['current']['condition']['icon']}', // WeatherAPI trả về sẵn đường dẫn ảnh
          'cityName': data['location']['name'],
        };
      } else {
        _log('Lỗi API thời tiết: ${response.statusCode} - ${response.body}');
        return Future.error(
            'Không thể lấy dữ liệu thời tiết. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      _log('Lỗi khi lấy thời tiết: $e');
      return Future.error('Không thể lấy dữ liệu thời tiết: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'd54979f0754232e31970bf9e7cd74598';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[WeatherService] $message');
    }
  }

  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có được bật không.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log('Dịch vụ vị trí bị tắt.');
      return Future.error('Dịch vụ vị trí bị tắt.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _log('Quyền truy cập vị trí bị từ chối.');
        return Future.error('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _log('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
      return Future.error(
          'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng cấp quyền trong cài đặt ứng dụng.');
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
      final lat = position.latitude;
      final lon = position.longitude;

      _log('Đang lấy thời tiết cho Lat: $lat, Lon: $lon');

      final uri = Uri.parse(
          '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi'); // units=metric cho độ C, lang=vi cho tiếng Việt

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('Dữ liệu thời tiết đã nhận: $data');
        return {
          'temperature': data['main']['temp'],
          'description': data['weather'][0]['description'],
          'humidity': data['main']['humidity'],
          'windSpeed': data['wind']['speed'],
          'icon': data['weather'][0]['icon'],
          'cityName': data['name'],
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

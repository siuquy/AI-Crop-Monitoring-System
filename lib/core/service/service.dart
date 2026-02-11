import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '0056d101e71897d2bb4f85c28dae7d11';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> getWeather({
    required double lat,
    required double lon,
  }) async {
    final url =
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=vi';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Không lấy được dữ liệu thời tiết');
    }
  }
}

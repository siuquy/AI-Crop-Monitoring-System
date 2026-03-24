import 'dart:convert';
import 'package:http/http.dart' as http;

class FarmService {
  static Future<List<Map<String, dynamic>>> getFarms() async {
    final uri = Uri.parse('http://10.0.2.2:5298/api/Farms');

    final res = await http.get(uri);
    final json = jsonDecode(res.body);

    final list = json['data'] as List;

    return list
        .map((item) => {
              'farmId': item['farmId'].toString(),
              'farmName': item['farmName'].toString(),
            })
        .toList();
  }
}

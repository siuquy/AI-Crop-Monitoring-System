import 'dart:convert';
import 'package:http/http.dart' as http;

class CropService {
  static Future<Map<String, String>> getCropMap() async {
    final uri = Uri.parse('http://10.0.2.2:5298/api/Crops');

    final res = await http.get(uri);
    final json = jsonDecode(res.body);

    final list = json['data'] as List;

    return {
      for (var item in list)
        item['cropId'].toString(): (item['cropName'] ?? 'Không rõ').toString()
    };
  }
}

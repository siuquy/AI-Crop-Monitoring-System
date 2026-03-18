import 'dart:convert';
import 'package:http/http.dart' as http;

class BedService {
  static Future<Map<String, Map<String, dynamic>>> getBedMap() async {
    final uri = Uri.parse('http://10.0.2.2:5298/api/Beds');

    final res = await http.get(uri);
    final json = jsonDecode(res.body);

    final list = json['data'] as List;

    return {
      for (var item in list)
        item['bedId'].toString(): {
          'bedName': item['bedName'],
          'plotId': item['plotId'],
        }
    };
  }
}

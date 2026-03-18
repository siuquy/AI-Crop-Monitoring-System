import 'dart:convert';
import 'package:http/http.dart' as http;

class PlotService {
  static Future<Map<String, Map<String, dynamic>>> getPlotMap() async {
    final uri = Uri.parse('http://10.0.2.2:5298/api/Plots');

    final res = await http.get(uri);
    final json = jsonDecode(res.body);

    final list = json['data'] as List;

    return {
      for (var item in list)
        item['plotId'].toString(): {
          'plotName': item['plotName'],
          'farmName': item['farmName'],
        }
    };
  }
}

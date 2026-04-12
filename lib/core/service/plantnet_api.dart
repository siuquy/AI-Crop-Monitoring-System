import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantNetApi {
  static const String _baseUrl = 'https://my-api.plantnet.org/v2/identify/all';

  static Future<Map<String, dynamic>> detectPlant(File imageFile) async {
    try {
      final String apiKey = dotenv.env['PLANTNET_API_KEY'] ?? '';
      final uri = Uri.parse('$_baseUrl?api-key=$apiKey');
      final request = http.MultipartRequest('POST', uri);

      request.fields['organs'] = 'auto';

      final ext = imageFile.path.split('.').last.toLowerCase();
      MediaType contentType = MediaType('image', 'jpeg');
      if (ext == 'png') {
        contentType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        contentType = MediaType('image', 'webp');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
          contentType: contentType,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['results'] != null) {
        final List<dynamic> results = data['results'];
        if (results.isNotEmpty) {
          final bestMatch = results.first;
          final species = bestMatch['species'];
          final String scientificName =
              species['scientificNameWithoutAuthor'] ?? 'Không rõ';
          final List<dynamic>? commonNamesList = species['commonNames'];
          final String commonName =
              (commonNamesList != null && commonNamesList.isNotEmpty)
                  ? commonNamesList.first.toString()
                  : 'Không có tên thông thường';
          final double confidence = (bestMatch['score'] ?? 0.0).toDouble();

          return {
            'name': scientificName,
            'commonName': commonName,
            'confidence': confidence,
          };
        }
      } else if (response.statusCode == 404) {
        throw Exception(
            'Không nhận diện được cây trồng. Vui lòng chụp rõ lá, hoa hoặc quả của cây.');
      } else if (response.statusCode == 429) {
        throw Exception('API PlantNet đã hết lượt truy cập trong ngày.');
      }

      throw Exception('Lỗi hệ thống AI (Mã lỗi: ${response.statusCode}).');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

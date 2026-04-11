import 'dart:io';
import 'api_client.dart'; // Import ApiClient của hệ thống

class PlantNetApi {
  static Future<Map<String, dynamic>> detectPlant(File imageFile) async {
    try {
      print('Sending request to Backend PlantNet API...');

      // Gọi qua API backend thay vì gọi trực tiếp PlantNet API
      final response = await ApiClient.instance.postMultipart(
        '/api/PlantNet/identify', // Endpoint nội bộ
        file: imageFile,
        fileField: 'image', // Theo như cấu hình của backend C# là "image"
        fields: {
          'organ': 'auto', // Theo như cấu hình của backend C# là "organ"
        },
      );

      // ApiClient đã handle response JSON cho ta, và backend bọc bằng { "success": true, "data": ... }
      if (response != null && response['success'] == true) {
        final data = response['data'];
        final List<dynamic>? results = data?['results'];

        if (data != null && data['remainingRequests'] == 0) {
          throw Exception(
              'API PlantNet đã hết lượt truy cập trong ngày (Quota exceeded).');
        }

        if (results != null && results.isNotEmpty) {
          final bestMatch = results.first;
          final species = bestMatch['species'];

          final String scientificName =
              species['scientificNameWithoutAuthor'] ?? 'Unknown Species';

          final List<dynamic>? commonNamesList = species['commonNames'];
          final String commonName =
              (commonNamesList != null && commonNamesList.isNotEmpty)
                  ? commonNamesList.first.toString()
                  : 'No common name available';

          final double confidence = (bestMatch['score'] ?? 0.0).toDouble();

          return {
            'name': scientificName,
            'commonName': commonName,
            'confidence': confidence,
          };
        } else {
          throw Exception(
              'Không nhận diện được cây trồng trong ảnh. Vui lòng chụp hình ảnh rõ nét hơn và thử lại.');
        }
      } else {
        throw Exception(
            'Failed to identify plant. Server response was not successful.');
      }
    } on ApiException catch (e) {
      // Catch từ Exception của ApiClient
      print('ApiException occurred: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception(
          'An unexpected error occurred while identifying the plant: $e');
    }
  }
}

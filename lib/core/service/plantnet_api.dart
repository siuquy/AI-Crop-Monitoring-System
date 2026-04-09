import 'dart:io';
import 'package:dio/dio.dart';

class PlantNetApi {
  static const String _apiKey = '2b10jEFLitN5AEbj11Hb37bZlO';
  static const String _baseUrl = 'https://my-api.plantnet.org/v2/identify/all';

  final Dio _dio;

  PlantNetApi({Dio? dio}) : _dio = dio ?? Dio();

  Future<Map<String, dynamic>> detectPlant(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        'organs': 'leaf',
        'images': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      Map<String, dynamic> queryParams = {
        'api-key': _apiKey,
      };

      print('Sending request to PlantNet API...');

      Response response = await _dio.post(
        _baseUrl,
        data: formData,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Request status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<dynamic>? results = data['results'];

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
          throw Exception('No plant identified in the image.');
        }
      } else {
        throw Exception(
            'Failed to identify plant. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException occurred: ${e.message}');
      if (e.response != null) {
        print('Error response status: ${e.response?.statusCode}');
        print('Error response data: ${e.response?.data}');
      }

      String errorMessage =
          'Failed to connect to the plant identification service.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timed out. Please check your internet connection.';
      } else if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        errorMessage = 'Unauthorized. Please check your API key.';
      } else if (e.response?.statusCode == 404) {
        errorMessage =
            'Không nhận diện được cây trồng trong ảnh. Vui lòng chụp hình ảnh rõ nét hơn của lá hoặc hoa và thử lại.';
      } else if (e.response?.statusCode == 413) {
        errorMessage = 'The image file is too large.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception(
          'An unexpected error occurred while identifying the plant: $e');
    }
  }
}

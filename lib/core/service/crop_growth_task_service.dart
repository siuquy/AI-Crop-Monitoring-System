import 'api_client.dart';

class CropGrowthTaskService {
  static Future<List<dynamic>> getCropGrowthTasks() async {
    try {
      final response = await ApiClient.instance.get('/api/CropGrowthTask');
      if (response != null && response['success'] == true) {
        return response['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

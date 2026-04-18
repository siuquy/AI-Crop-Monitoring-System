import '../../models/iot_device.dart';
import '../../models/iot_data.dart';
import 'api_client.dart';

class IotService {
  static Future<List<IotDevice>> getDevices() async {
    final response = await ApiClient.instance.get('/api/IotDevices');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => IotDevice.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<List<IotData>> getIotDatas() async {
    final response = await ApiClient.instance.get('/api/IotDatas');
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => IotData.fromJson(json))
          .toList();
    }
    return [];
  }
}

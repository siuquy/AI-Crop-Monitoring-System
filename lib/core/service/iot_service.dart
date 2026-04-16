import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../../models/iot_device.dart';
import '../../models/iot_data.dart';

class IotService {
  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[IotService] $message');
    }
  }

  static Future<List<IotDevice>> getDevices() async {
    try {
      final response = await ApiClient.instance.get('/api/IotDevices');
      if (response != null &&
          response is Map<String, dynamic> &&
          response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => IotDevice.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      _log('Lỗi khi lấy danh sách thiết bị IoT: $e');
      return [];
    }
  }

  static Future<List<IotData>> getIotDatas() async {
    try {
      final response = await ApiClient.instance.get('/api/IotDatas');
      if (response != null &&
          response is Map<String, dynamic> &&
          response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((json) => IotData.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      _log('Lỗi khi lấy dữ liệu môi trường IoT: $e');
      return [];
    }
  }
}

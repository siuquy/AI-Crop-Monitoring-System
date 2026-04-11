import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ScanHistoryService {
  static const String _key = 'scan_history';

  /// Lưu một kết quả quét mới vào bộ nhớ cục bộ
  static Future<void> saveScan(
      String imagePath, Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> historyList = prefs.getStringList(_key) ?? [];

      // Tạo một record mới
      final newRecord = {
        'imagePath': imagePath,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Thêm vào đầu danh sách (mới nhất lên trước)
      historyList.insert(0, jsonEncode(newRecord));

      // Cập nhật lại xuống SharedPreferences
      await prefs.setStringList(_key, historyList);
    } catch (e) {
      debugPrint('Lỗi khi lưu lịch sử quét: $e');
    }
  }

  /// Lấy toàn bộ danh sách lịch sử quét
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = prefs.getStringList(_key) ?? [];

    return historyList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}

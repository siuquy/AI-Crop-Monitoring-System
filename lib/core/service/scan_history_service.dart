import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ScanHistoryService {
  static const String _key = 'scan_history';

  static Future<void> saveScan(
      String imagePath, Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> historyList = prefs.getStringList(_key) ?? [];

      final newRecord = {
        'imagePath': imagePath,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      };

      historyList.insert(0, jsonEncode(newRecord));

      await prefs.setStringList(_key, historyList);
    } catch (e) {
      debugPrint('Lỗi khi lưu lịch sử quét: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = prefs.getStringList(_key) ?? [];

    return historyList
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}

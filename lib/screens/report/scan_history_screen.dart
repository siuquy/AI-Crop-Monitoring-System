import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/scan_history_service.dart';
import '../task/ai_analysis_result_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ScanHistoryService.getHistory();
    setState(() {
      _historyList = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử quét'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    final result =
                        item['result'] as Map<String, dynamic>? ?? {};
                    final plantName = result['disease'] ??
                        result['name'] ??
                        result['diseaseName'] ??
                        'Không xác định';
                    final confidence = result['confidence'] != null
                        ? ((result['confidence'] as num) * 100)
                            .toStringAsFixed(1)
                        : '0.0';

                    // Format thời gian
                    DateTime? parsedDate;
                    if (item['timestamp'] != null) {
                      parsedDate = DateTime.tryParse(item['timestamp']);
                    }
                    final dateString = parsedDate != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(parsedDate)
                        : 'Không rõ thời gian';

                    final imagePath = item['imagePath'] as String?;
                    final imageFile =
                        imagePath != null ? File(imagePath) : null;
                    final hasImage =
                        imageFile != null && imageFile.existsSync();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () {
                          if (hasImage) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AiAnalysisResultScreen(
                                  image: imageFile!,
                                  analysisData: result,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Không tìm thấy hình ảnh cho lịch sử này.')),
                            );
                          }
                        },
                        contentPadding: const EdgeInsets.all(12),
                        leading: hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  imageFile,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                        title: Text(
                          plantName.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Độ tin cậy: $confidence%',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(dateString,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử quét nào.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

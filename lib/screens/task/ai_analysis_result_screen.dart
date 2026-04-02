import 'dart:io';
import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color darkGreen = Color(0xFF2E7D32);

class AiAnalysisResultScreen extends StatelessWidget {
  final File image;
  final Map<String, dynamic> analysisData;

  const AiAnalysisResultScreen({
    super.key,
    required this.image,
    required this.analysisData,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = analysisData['isHealthy'] ?? false;
    final String diseaseName = analysisData['diseaseName'] ?? 'Không xác định';
    final double confidence = (analysisData['confidence'] ?? 0.0) * 100;
    final String description = analysisData['description'] ?? '';
    final List<String> symptoms =
        List<String>.from(analysisData['symptoms'] ?? []);
    final List<String> treatment =
        List<String>.from(analysisData['treatment'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả phân tích'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF3F6F9),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildImagePreview(),
          const SizedBox(height: 24),
          _buildResultSummary(isHealthy, diseaseName, confidence, description),
          if (!isHealthy) ...[
            const SizedBox(height: 20),
            _buildInfoSection(
                'Triệu chứng', symptoms, Icons.coronavirus_rounded),
            const SizedBox(height: 20),
            _buildInfoSection(
                'Phương pháp điều trị', treatment, Icons.healing_rounded),
          ],
          const SizedBox(height: 30),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Image.file(
        image,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildResultSummary(bool isHealthy, String diseaseName,
      double confidence, String description) {
    final Color indicatorColor = isHealthy ? Colors.green : Colors.orange;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: indicatorColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    diseaseName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: indicatorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isHealthy)
              Text(
                'Độ chính xác: ${confidence.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                  fontSize: 15, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: darkGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5.0, right: 8.0),
                      child:
                          Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit_document, color: Colors.white),
            label: const Text('Tạo báo cáo sự cố',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              // TODO: Navigate to Create Report Screen with pre-filled data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Chuyển đến màn hình tạo báo cáo...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Phản hồi: Kết quả sai'),
            onPressed: () {
              // TODO: Call AIService.submitFeedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang gửi phản hồi...')),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:acmms/models/task_model.dart';
import 'report_detail_screen.dart';

class ScanResultScreen extends StatelessWidget {
  final String imagePath;
  final String diseaseName;
  final double confidence;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
  });

  TaskModel get aiTask => TaskModel(
        id: 'scan_ai',
        title: diseaseName,
        description: 'AI phát hiện dấu hiệu bất thường trên lá cây',
        taskType: 'Chẩn đoán bệnh',
        cropName: 'Cà chua',
        season: 'Vụ Đông Xuân',
        field: 'Trang trại A',
        area: 'Ruộng 1',
        bed: 'Luống 12',
        startTime: '',
        endTime: '',
        date: '',
        status: TaskStatus.urgent,
        isUrgent: true,
        assignedBy: 'AI Scan',
        assignedRole: 'Hệ thống',
        avatarIcon: Icons.bug_report,
        imageAsset: '',
      );

  @override
  Widget build(BuildContext context) {
    final task = aiTask;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả quét'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            _DiagnosisCard(
              diseaseName: diseaseName,
              cropName: task.cropName,
              confidence: confidence,
            ),

            const SizedBox(height: 16),

            _SectionTitle('📍 Vị trí phát hiện'),
            const SizedBox(height: 8),
            _LocationGrid(task: task),

            const SizedBox(height: 16),

            _SectionTitle('🤖 Giải thích từ AI'),
            const SizedBox(height: 8),
            _AiExplanation(diseaseName: diseaseName),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text(
                  'Tạo báo cáo',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FCFC5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(
                        imagePath: imagePath,
                        diseaseName: diseaseName,
                        confidence: confidence,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final String diseaseName;
  final String cropName;
  final double confidence;

  const _DiagnosisCard({
    required this.diseaseName,
    required this.cropName,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chẩn đoán bệnh',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  diseaseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(cropName),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationGrid extends StatelessWidget {
  final TaskModel task;

  const _LocationGrid({required this.task});

  Widget _item(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _item('Trang trại', task.field)),
              Expanded(child: _item('Ruộng', task.area)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _item('Khu', task.area)),
              Expanded(child: _item('Luống', task.bed)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiExplanation extends StatelessWidget {
  final String diseaseName;

  const _AiExplanation({required this.diseaseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Phát hiện các đốm bất thường trên lá có hình tròn và màu sẫm – '
        'đặc trưng của bệnh $diseaseName.\n\n'
        'AI khuyến nghị kiểm tra và xử lý sớm để tránh lây lan.',
        style: const TextStyle(height: 1.4),
      ),
    );
  }
}

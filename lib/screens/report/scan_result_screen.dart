import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/service/report_service.dart';
import '../../models/report.dart';
import 'report_detail_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> analysisResult;
  final String farmId;
  final String plotId;
  final String bedId;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
    required this.farmId,
    required this.plotId,
    required this.bedId,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isCreatingReport = false;

  Future<void> _createReport() async {
    setState(() {
      _isCreatingReport = true;
    });

    try {
      final String title = widget.analysisResult['diseaseName'] ?? 'Báo cáo AI';
      final String description =
          widget.analysisResult['description'] ?? 'Không có mô tả.';

      // Call the real API service to create the report
      final newReport = await ReportService.createReport(
        title: title,
        description: description,
        image: File(widget.imagePath),
        farmId: widget.farmId,
        plotId: widget.plotId,
        bedId: widget.bedId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo báo cáo thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the detail screen with the new Report object
      // This fixes the compilation error.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(report: newReport),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo báo cáo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String diseaseName =
        widget.analysisResult['diseaseName'] ?? 'Không xác định';
    final String description =
        widget.analysisResult['description'] ?? 'Không có mô tả.';
    final List<dynamic> symptoms = widget.analysisResult['symptoms'] ?? [];
    final List<dynamic> treatment = widget.analysisResult['treatment'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả phân tích AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(widget.imagePath)),
            ),
            const SizedBox(height: 24),
            Text(
              diseaseName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (symptoms.isNotEmpty)
              _buildInfoSection(
                context,
                title: 'Triệu chứng',
                icon: Icons.local_hospital_outlined,
                items: symptoms,
                iconColor: Colors.orange.shade700,
              ),
            if (treatment.isNotEmpty)
              _buildInfoSection(
                context,
                title: 'Phương pháp điều trị',
                icon: Icons.healing_outlined,
                items: treatment,
                iconColor: Colors.green.shade700,
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isCreatingReport
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _createReport,
                icon: const Icon(Icons.add_chart),
                label: const Text('Tạo báo cáo từ kết quả này'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<dynamic> items,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ',
                      style: TextStyle(fontSize: 16, color: Colors.black54)),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

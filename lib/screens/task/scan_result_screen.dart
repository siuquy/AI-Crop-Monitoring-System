import 'dart:io';
import 'package:flutter/material.dart';
import 'ai_service.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> analysisResult;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  bool _isUploading = false;
  bool _isSubmittingFeedback = false;

  @override
  Widget build(BuildContext context) {
    final String diseaseName =
        widget.analysisResult['diseaseName'] ?? 'Không xác định';
    final double confidence = widget.analysisResult['confidence'] ?? 0.0;
    final String description =
        widget.analysisResult['description'] ?? 'Không có mô tả.';
    final List<String> symptoms =
        List<String>.from(widget.analysisResult['symptoms'] ?? []);
    final List<String> treatment =
        List<String>.from(widget.analysisResult['treatment'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả phân tích AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF6F8F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCard(),
            const SizedBox(height: 20),
            _buildResultHeader(diseaseName, confidence),
            _buildFeedbackButton(),
            const Divider(height: 32),
            _buildSection('Mô tả', description),
            if (symptoms.isNotEmpty)
              _buildListSection('Triệu chứng nhận biết', symptoms),
            if (treatment.isNotEmpty)
              _buildListSection('Đề xuất xử lý', treatment),
          ],
        ),
      ),
      bottomNavigationBar:
          _buildActionButtons(context, diseaseName, confidence),
    );
  }

  Widget _buildImageCard() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(widget.imagePath),
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildResultHeader(String diseaseName, double confidence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả chẩn đoán:',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          diseaseName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.verified, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 6),
            Text(
              'Độ chính xác: ${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: Colors.grey.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5.0, right: 8.0),
                      child: Icon(Icons.circle, size: 8, color: primaryTeal),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style:
                            TextStyle(color: Colors.grey.shade800, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton() {
    // Don't show feedback button if the plant is healthy
    if (widget.analysisResult['isHealthy'] == true) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _isSubmittingFeedback || _isUploading
            ? null
            : _reportIncorrectAnalysis,
        icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
        label: Text(
          _isSubmittingFeedback ? 'Đang gửi...' : 'Báo cáo không chính xác',
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _reportIncorrectAnalysis() async {
    setState(() {
      _isSubmittingFeedback = true;
    });

    try {
      await AIService.submitFeedback(
        image: File(widget.imagePath),
        analysisData: widget.analysisResult,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã giúp chúng tôi cải thiện AI!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi phản hồi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingFeedback = false);
      }
    }
  }

  Future<void> _createReport() async {
    setState(() {
      _isUploading = true;
    });

    try {
      await AIService.createReport(
        image: File(widget.imagePath),
        analysisData: widget.analysisResult,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo và gửi báo cáo thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildActionButtons(
      BuildContext context, String diseaseName, double confidence) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  _isUploading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Quét lại'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _isUploading || _isSubmittingFeedback ? null : _createReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.description),
              label: Text(_isUploading ? 'Đang gửi...' : 'Tạo báo cáo'),
            ),
          ),
        ],
      ),
    );
  }
}

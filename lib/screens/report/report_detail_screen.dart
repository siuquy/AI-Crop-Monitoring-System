import 'dart:io';
import 'package:flutter/material.dart';

class ReportDetailScreen extends StatefulWidget {
  final String imagePath;
  final String diseaseName;
  final double confidence;

  const ReportDetailScreen({
    super.key,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String selectedFarm = 'Green Farm 1';
  String selectedArea = 'Khu B';
  String selectedBed = 'Luống 05';
  String selectedIssue = 'Nấm lá';

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    descriptionController.text =
        'Phát hiện các đốm vàng nâu trên lá ${widget.diseaseName}, '
        'tập trung chủ yếu ở phần ngọn. Có dấu hiệu lan rộng nhanh...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tạo Báo cáo Công việc',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Tiêu đề báo cáo *'),
            _inputBox(
              child: Text(
                'Bệnh ${widget.diseaseName} - $selectedArea',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            _label('Trang trại *'),
            _dropdown(selectedFarm, ['Green Farm 1', 'Green Farm 2'],
                (v) => setState(() => selectedFarm = v!)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Khu *'),
                      _dropdown(selectedArea, ['Khu A', 'Khu B'],
                          (v) => setState(() => selectedArea = v!)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Luống *'),
                      _dropdown(selectedBed, ['Luống 01', 'Luống 05'],
                          (v) => setState(() => selectedBed = v!)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Loại vấn đề'),
            _dropdown(selectedIssue, ['Nấm lá', 'Sâu bệnh'],
                (v) => setState(() => selectedIssue = v!)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('Mô tả hiện trạng'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ AI gợi ý',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1FCFC5),
                    ),
                  ),
                )
              ],
            ),
            _textArea(descriptionController),
            const SizedBox(height: 16),
            _label('Ghi chú'),
            _textArea(noteController, hint: 'Thêm ghi chú bổ sung...'),
            const SizedBox(height: 16),
            _label('Hình ảnh đính kèm'),
            const SizedBox(height: 8),
            Row(
              children: [
                _imagePreview(widget.imagePath, true),
                const SizedBox(width: 12),
                _imagePreview(widget.imagePath, false),
                const SizedBox(width: 12),
                _addImageBox(),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FCFC5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Gửi báo cáo ➜',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: child,
    );
  }

  Widget _dropdown(
      String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _boxDecoration(),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _textArea(TextEditingController controller, {String? hint}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration.collapsed(
          hintText: hint,
        ),
      ),
    );
  }

  Widget _imagePreview(String path, bool isDetected) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        if (isDetected)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Đã phân tích',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _addImageBox() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.add_a_photo, color: Colors.grey),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}

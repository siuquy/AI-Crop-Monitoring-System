import 'dart:io';
import 'package:flutter/material.dart';
import 'create_report_screen.dart'; // Trang mới để tạo báo cáo
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

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
  late Future<Map<String, String>> _locationNamesFuture;

  @override
  void initState() {
    super.initState();
    _locationNamesFuture = _fetchLocationNames();
  }

  Future<Map<String, String>> _fetchLocationNames() async {
    // Tải song song để tăng hiệu suất
    final results = await Future.wait([
      FarmService.getFarmMap(),
      PlotService.getPlotMap(),
      BedService.getBedMap(),
    ]);

    final farmMap = results[0] as Map<String, String>;
    final plotMap = results[1] as Map<String, Map<String, dynamic>>;
    final bedMap = results[2] as Map<String, Map<String, dynamic>>;

    return {
      'farmName': farmMap[widget.farmId] ?? 'Không rõ',
      'plotName': plotMap[widget.plotId]?['plotName']?.toString() ?? 'Không rõ',
      'bedName': bedMap[widget.bedId]?['bedName']?.toString() ?? 'Không rõ',
    };
  }

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
            _buildLocationInfo(),
            const Divider(height: 32),
            _buildResultHeader(diseaseName, confidence),
            const SizedBox(height: 16),
            _buildSection('Mô tả', description),
            if (symptoms.isNotEmpty)
              _buildListSection('Triệu chứng nhận biết', symptoms),
            if (treatment.isNotEmpty)
              _buildListSection('Đề xuất xử lý', treatment),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CreateReportScreen(
                imagePath: widget.imagePath,
                analysisResult: widget.analysisResult,
                farmId: widget.farmId,
                plotId: widget.plotId,
                bedId: widget.bedId,
              ),
            ));
          },
          icon: const Icon(Icons.description_outlined),
          label: const Text('Tiếp tục tạo báo cáo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
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

  Widget _buildLocationInfo() {
    return FutureBuilder<Map<String, String>>(
      future: _locationNamesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi tải vị trí'));
        }
        final names = snapshot.data ?? {};
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vị trí: ${names['farmName']} - ${names['plotName']} - ${names['bedName']}',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        );
      },
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
}

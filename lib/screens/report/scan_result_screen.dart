import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'create_report_screen.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';

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
  late bool _isHealthy;
  late Future<Map<String, String>> _locationNamesFuture;

  @override
  void initState() {
    super.initState();
    _isHealthy = widget.analysisResult['isHealthy'] ?? false;
    _locationNamesFuture = _fetchLocationNames();
  }

  Future<Map<String, String>> _fetchLocationNames() async {
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

  Future<void> _handleCompletion() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã ghi nhận cây trồng khỏe mạnh.'),
        backgroundColor: Colors.green,
      ),
    );
    // Quay về màn hình trước đó (ví dụ: Chi tiết công việc)
    Navigator.of(context).pop();
  }

  Future<void> _saveImageToGallery() async {
    Future<void> performSave() async {
      final result = await SaverGallery.saveFile(
          filePath: widget.imagePath,
          fileName: 'plant_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          skipIfExists: false);
      if (!mounted) return;

      if (result?.isSuccess == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu ảnh vào thư viện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Không thể lưu ảnh.');
      }
    }

    try {
      if (Platform.isAndroid) {
        // Xin cấp quyền trước trên Android để đảm bảo tương thích mọi phiên bản
        await Permission.storage.request();
        await Permission.photos.request();

        await performSave();
      } else {
        var status = await Permission.photos.request();
        if (status.isGranted) {
          await performSave();
        } else if (status.isPermanentlyDenied) {
          if (!mounted) return;
          openAppSettings();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Quyền truy cập thư viện ảnh đã bị từ chối.'),
            backgroundColor: Colors.orange,
          ));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi khi lưu ảnh: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả quét AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationInfo(),
            const SizedBox(height: 24),
            _buildResultCard(),
            const SizedBox(height: 16),
            _buildImageSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isHealthy ? _buildCompleteButton() : _buildCreateReportButton(),
      ),
    );
  }

  Widget _buildResultCard() {
    final String title = widget.analysisResult['diseaseName'];
    final String description = widget.analysisResult['description'];
    final Color statusColor = _isHealthy ? Colors.green : Colors.orange;
    final IconData statusIcon =
        _isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon,
                  color: statusColor.alpha == 255 ? statusColor : Colors.grey,
                  size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: statusColor.alpha == 255
                          ? statusColor
                          : Colors.grey.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.grey.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ảnh đã quét:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton.icon(
                onPressed: _saveImageToGallery,
                icon: const Icon(Icons.save_alt),
                label: const Text('Lưu ảnh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return ElevatedButton.icon(
      onPressed: _handleCompletion,
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Hoàn thành'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCreateReportButton() {
    return ElevatedButton.icon(
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
      icon: const Icon(Icons.edit_note),
      label: const Text('Tạo báo cáo'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
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
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'create_report_screen.dart'; // Trang mới để tạo báo cáo
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/report_service.dart';
import '../../core/service/api_client.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isSaving = false;

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

  Future<void> _saveHealthyReport() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ReportService.createReport(
        title: 'Kiểm tra định kỳ - Tình trạng tốt',
        description:
            'Cây trồng được ghi nhận là khỏe mạnh, không có dấu hiệu sâu bệnh tại thời điểm kiểm tra.',
        image: File(widget.imagePath),
        farmId: widget.farmId,
        plotId: widget.plotId,
        bedId: widget.bedId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu báo cáo tình trạng tốt thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi không mong muốn: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
        // Trên Android, saver_gallery sử dụng MediaStore và không cần quyền runtime
        // để lưu ảnh vào thư viện. Chúng ta có thể lưu trực tiếp.
        await performSave();
      } else {
        // Trên iOS, chúng ta cần yêu cầu quyền truy cập thư viện ảnh.
        var status = await Permission.photos.request();

        if (status.isGranted) {
          await performSave();
        } else if (status.isPermanentlyDenied) {
          // Xử lý trường hợp người dùng từ chối vĩnh viễn
          if (!mounted) return;
          // Mở cài đặt ứng dụng để người dùng có thể cấp quyền thủ công
          openAppSettings();
        } else {
          // Xử lý trường hợp người dùng từ chối
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
    final String diseaseName =
        widget.analysisResult['diseaseName'] ?? 'Không xác định';
    final double confidence = widget.analysisResult['confidence'] ?? 0.0;
    final String description =
        widget.analysisResult['description'] ?? 'Không có mô tả.';
    final List<String> symptoms =
        List<String>.from(widget.analysisResult['symptoms'] ?? []);
    final List<String> treatment =
        List<String>.from(widget.analysisResult['treatment'] ?? []);
    final bool isHealthy = widget.analysisResult['isHealthy'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả phân tích AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: _saveImageToGallery,
            tooltip: 'Lưu ảnh vào thư viện',
          ),
        ],
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
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHealthy) ...[
                    ElevatedButton.icon(
                      onPressed: _saveHealthyReport,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Lưu báo cáo (Tình trạng tốt)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
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
                    label: Text(isHealthy
                        ? 'Tạo báo cáo tùy chỉnh'
                        : 'Tiếp tục tạo báo cáo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
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

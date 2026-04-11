// d:\code_mobile\flutter\acmms\lib\screens\report\scan_result_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../task/ai_service.dart';
import '../../core/service/plantnet_api.dart';
import 'create_report_screen.dart'; // Import màn hình tạo báo cáo

class ScanResultScreen extends StatelessWidget {
  final File image;
  final Map<String, dynamic> result;
  final String farmId;
  final String farmName;
  final String plotId;
  final String plotName;
  final String bedId;
  final String bedName;
  final String? seasonId;
  final String? ownerId;

  const ScanResultScreen({
    super.key,
    required this.image,
    required this.result,
    required this.farmId,
    required this.farmName,
    required this.plotId,
    required this.plotName,
    required this.bedId,
    required this.bedName,
    this.seasonId,
    this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    // Trích xuất các thông tin từ result (hỗ trợ cả PlantNet API và AI Service)
    final String plantName = result['name']?.toString() ??
        result['diseaseName']?.toString() ??
        result['Tên bệnh']?.toString() ??
        'Không rõ';
    final String commonName = result['commonName'] ?? '';
    final double confidence = result['confidence'] != null
        ? (result['confidence'] as num).toDouble()
        : 0.0;

    // Khai thác triệt để các trường dữ liệu AI trả về để đảm bảo luôn có nội dung
    String aiDesc = result['description']?.toString() ??
        result['Description']?.toString() ??
        '';
    final symptoms = result['symptoms'] as List<dynamic>? ?? [];
    final treatment = result['treatment'] as List<dynamic>? ?? [];

    StringBuffer descBuffer = StringBuffer();
    if (aiDesc.trim().isNotEmpty) {
      descBuffer.writeln(aiDesc.trim());
    }
    if (symptoms.isNotEmpty) {
      descBuffer.writeln('\n* Triệu chứng:');
      for (var s in symptoms) descBuffer.writeln('  - $s');
    }
    if (treatment.isNotEmpty) {
      descBuffer.writeln('\n* Cách xử lý:');
      for (var t in treatment) descBuffer.writeln('  - $t');
    }

    // Vét cạn BẤT KỲ key nào khác mà AI trả về (ngay cả khi đã có symptoms)
    final knownKeys = [
      'isHealthy',
      'confidence',
      'diseaseName',
      'name',
      'commonName',
      'description',
      'Description',
      'symptoms',
      'treatment'
    ];
    result.forEach((key, value) {
      if (!knownKeys.contains(key) && value != null) {
        if (value is List) {
          if (value.isNotEmpty) {
            descBuffer.writeln('\n* $key:');
            for (var item in value) descBuffer.writeln('  - $item');
          }
        } else if (value.toString().trim().isNotEmpty) {
          descBuffer.writeln('\n* $key: $value');
        }
      }
    });

    String description = descBuffer.toString().trim();
    if (description.isEmpty) {
      bool isHealthy = result['isHealthy'] == true ||
          plantName.toLowerCase().contains('khỏe mạnh');
      if (isHealthy) {
        description =
            'Cây trồng có vẻ khỏe mạnh. Không phát hiện dấu hiệu bất thường nào trên hình ảnh.';
      } else {
        description =
            'Đã nhận diện được bệnh nhưng chưa có mô tả chi tiết từ AI. Vui lòng kiểm tra lại hình ảnh hoặc thử chụp từ góc độ rõ nét hơn.';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết kết quả quét"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hiển thị ảnh đã quét
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(image,
                      width: double.infinity, height: 250, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton.extended(
                    heroTag: 'retry_scan',
                    onPressed: () => _showRetryMenu(context),
                    backgroundColor: Colors.white.withOpacity(0.9),
                    foregroundColor: Colors.teal,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Thử ảnh khác'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Thông tin vị trí
            _buildSection(
              title: "Vị trí",
              content: "$farmName > $plotName > $bedName",
              icon: Icons.location_on,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 16),

            // 3. Kết quả nhận diện (Tên, độ tin cậy)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics, color: Color(0xFF1FCFC5)),
                        SizedBox(width: 8),
                        Text(
                          "Kết quả phân tích",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow("Tên/Bệnh:", plantName, isBold: true),
                    if (commonName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow("Tên thông thường:", commonName),
                    ],
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      "Độ tin cậy:",
                      "${(confidence * 100).toStringAsFixed(1)}%",
                      valueColor: Colors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Field mô tả tình trạng cây
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "Mô tả tình trạng cây",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 15, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 5. Hai nút hành động
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text(
                      "Hoàn thành",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Chuyển sang màn hình tạo báo cáo với dữ liệu đã được scan
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateReportScreen(
                            imagePath: image.path,
                            analysisResult: result,
                            farmId: farmId,
                            plotId: plotId,
                            bedId: bedId,
                            seasonId: seasonId,
                            ownerId: ownerId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem),
                    label: const Text(
                      "Tạo báo cáo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF1FCFC5), // primaryTeal
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title,
      required String content,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  void _showRetryMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _scanAgain(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                _scanAgain(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanAgain(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70, // Giảm chất lượng ảnh xuống 70%
      maxWidth: 1080, // Giới hạn độ phân giải tối đa (chiều rộng)
      maxHeight: 1080, // Giới hạn độ phân giải tối đa (chiều cao)
    );
    if (pickedFile == null) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Đang phân tích lại..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Tạm thời vô hiệu hóa Gemini, chỉ dùng API PlantNet
      final result = await PlantNetApi.detectPlant(File(pickedFile.path));
      if (!context.mounted) return;
      Navigator.pop(context); // Đóng dialog loading

      // Thay thế màn hình hiện tại bằng màn hình kết quả mới
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            image: File(pickedFile.path),
            result: result,
            farmId: farmId,
            farmName: farmName,
            plotId: plotId,
            plotName: plotName,
            bedId: bedId,
            bedName: bedName,
            seasonId: seasonId,
            ownerId: ownerId,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Đóng dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích: $e')),
      );
    }
  }
}

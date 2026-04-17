import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/service/plant_service.dart';
import '../../shared/ai_result_widget.dart';
import 'create_report_screen.dart';

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
            _buildSection(
              title: "Vị trí",
              content: "$farmName > $plotName > $bedName",
              icon: Icons.location_on,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(color: Colors.purple.shade100),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.purple.shade600, size: 22),
                      const SizedBox(width: 8),
                      const Text('Phân tích chi tiết từ AI',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ],
                  ),
                  const Divider(height: 24),
                  AiResultWidget(aiData: result),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
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
      Map<String, dynamic> result;
      final file = File(pickedFile.path);
      result = await PlantService.analyzePlant(file);

      if (!context.mounted) return;
      Navigator.pop(context);
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích: $e')),
      );
    }
  }
}

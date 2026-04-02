import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../task/ai_service.dart';
import 'scan_result_screen.dart';

/// Một màn hình tạm thời để xử lý luồng quét bằng camera.
/// Nó sẽ tự động mở camera, xử lý phân tích AI và điều hướng đến màn hình kết quả.
class CameraScanScreen extends StatefulWidget {
  final String farmId;
  final String plotId;
  final String bedId;
  const CameraScanScreen({
    super.key,
    required this.farmId,
    required this.plotId,
    required this.bedId,
  });

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Kích hoạt luồng quét ngay khi màn hình được xây dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanWithAI();
    });
  }

  Future<void> _scanWithAI() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    // Nếu người dùng hủy camera, quay lại màn hình trước đó.
    if (pickedFile == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Hiển thị hộp thoại đang tải trong khi chờ AI phân tích.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Đang phân tích bằng AI..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await AIService.analyzePlantImage(File(pickedFile.path));
      if (mounted) Navigator.of(context).pop(); // Đóng hộp thoại đang tải

      if (!mounted) return;

      // Điều hướng đến màn hình kết quả với dữ liệu chính xác.
      // Lỗi của bạn đã được khắc phục ở đây bằng cách truyền một Map `analysisResult`.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ScanResultScreen(
          imagePath: pickedFile.path,
          analysisResult: result,
          farmId: widget.farmId,
          plotId: widget.plotId,
          bedId: widget.bedId,
        ),
      ));
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Đóng hộp thoại đang tải
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phân tích: $e')),
        );
        // Quay lại màn hình trước đó nếu có lỗi.
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màn hình này chủ yếu hiển thị trạng thái đang chờ.
    return Scaffold(
      appBar: AppBar(title: const Text("Quét bằng Camera")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Đang mở camera..."),
          ],
        ),
      ),
    );
  }
}

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

enum _ScanState { openingCamera, analyzing }

class _CameraScanScreenState extends State<CameraScanScreen> {
  final ImagePicker _picker = ImagePicker();
  _ScanState _state = _ScanState.openingCamera;

  @override
  void initState() {
    super.initState();
    // Kích hoạt luồng quét ngay khi màn hình được xây dựng.
    // Sử dụng addPostFrameCallback để đảm bảo context đã sẵn sàng
    // và tránh các lỗi liên quan đến việc build widget.
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

    // Cập nhật giao diện để hiển thị trạng thái đang phân tích.
    if (mounted) {
      setState(() {
        _state = _ScanState.analyzing;
      });
    }

    try {
      final result = await AIService.analyzePlantImage(File(pickedFile.path));

      // Kiểm tra widget còn trong cây giao diện không trước khi điều hướng.
      if (!mounted) return;

      // Thay thế màn hình hiện tại bằng màn hình kết quả.
      // Điều này ngăn người dùng quay lại màn hình quét.
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
    return Scaffold(
      appBar: AppBar(title: const Text("Quét bằng Camera")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_state == _ScanState.openingCamera
                ? "Đang mở camera..."
                : "Đang phân tích bằng AI..."),
          ],
        ),
      ),
    );
  }
}

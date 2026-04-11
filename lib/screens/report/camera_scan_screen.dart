import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/service/plantnet_api.dart';
import '../../core/service/scan_history_service.dart'; // Import service lịch sử
import 'scan_result_screen.dart';

class CameraScanScreen extends StatefulWidget {
  final String farmId;
  final String farmName;
  final String plotId;
  final String plotName;
  final String bedId;
  final String bedName;
  const CameraScanScreen({
    super.key,
    required this.farmId,
    required this.farmName,
    required this.plotId,
    required this.plotName,
    required this.bedId,
    required this.bedName,
  });

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage({ImageSource source = ImageSource.camera}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70, // Giảm chất lượng ảnh xuống 70%
      maxWidth: 1080, // Giới hạn độ phân giải tối đa (chiều rộng)
      maxHeight: 1080, // Giới hạn độ phân giải tối đa (chiều cao)
    );

    // Nếu người dùng hủy chọn ảnh, kiểm tra nếu chưa có ảnh nào thì quay lại
    if (pickedFile == null) {
      if (_image == null && mounted) Navigator.of(context).pop();
      return;
    }

    if (mounted) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null; // Clear old result when new image is picked
      });
    }
  }

  Future<void> _detectPlant() async {
    // If no image → show SnackBar
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ảnh (Please select an image)')),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      // Tạm thời vô hiệu hóa Gemini, chỉ dùng API PlantNet
      result = await PlantNetApi.detectPlant(_image!);

      // Lưu lại lịch sử quét xuống máy
      await ScanHistoryService.saveScan(_image!.path, result);

      if (mounted) {
        // Where result is updated
        setState(() {
          _result = result;
        });
      }
    } catch (e) {
      // Catch exception from API and show SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quét bằng Camera")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image Preview Section ---
            if (_image != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!,
                        width: double.infinity, height: 300, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _pickImage(source: ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Chụp lại"),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _pickImage(source: ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Thư viện"),
                      ),
                    ],
                  ),
                ],
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(child: Text("Đang mở camera...")),
              ),
            const SizedBox(height: 20),

            // --- Detect Button Section ---
            ElevatedButton(
              onPressed: _isLoading ? null : _detectPlant,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1FCFC5), // primaryTeal
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Phân tích ảnh (Detect)",
                      style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),

            // --- Result Section ---
            if (_result != null) ...[
              const Text("Kết quả phân tích:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Kết quả nhận diện: ${_result!['name'] ?? _result!['diseaseName'] ?? 'Không rõ'}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (_result!['commonName'] != null) ...[
                        Text("Tên thông thường: ${_result!['commonName']}",
                            style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        "Độ tin cậy: ${((_result!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(
                            fontSize: 15,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanResultScreen(
                        image: _image!,
                        result: _result!,
                        farmId: widget.farmId,
                        farmName: widget.farmName,
                        plotId: widget.plotId,
                        plotName: widget.plotName,
                        bedId: widget.bedId,
                        bedName: widget.bedName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF1FCFC5), // primaryTeal
                  foregroundColor: Colors.white,
                ),
                child: const Text("Xem chi tiết kết quả",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

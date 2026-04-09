import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/service/plantnet_api.dart';
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

  // Keep existing camera logic to just pick the image
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    // Nếu người dùng hủy camera, quay lại màn hình trước đó.
    if (pickedFile == null) {
      if (mounted) Navigator.of(context).pop();
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
      // Call PlantNet API (Where API is called)
      final api = PlantNetApi();
      final result = await api.detectPlant(_image!);

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
          SnackBar(content: Text(e.toString())),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 300, fit: BoxFit.cover),
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
                      Text("Tên khoa học: ${_result!['name']}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text("Tên thông thường: ${_result!['commonName']}",
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 8),
                      Text(
                        "Độ tin cậy: ${(_result!['confidence'] * 100).toStringAsFixed(1)}%",
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

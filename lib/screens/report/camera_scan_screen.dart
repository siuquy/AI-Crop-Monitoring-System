import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/service/plant_service.dart';
import '../../core/service/scan_history_service.dart';
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
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (pickedFile == null) {
      if (_image == null && mounted) Navigator.of(context).pop();
      return;
    }

    if (mounted) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
    }
  }

  Future<void> _detectPlant() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ảnh (Please select an image)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await PlantService.analyzePlant(_image!);

      await ScanHistoryService.saveScan(_image!.path, result);

      if (mounted) {
        setState(() {
          _result = result;
        });
      }
    } catch (e) {
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
            ElevatedButton(
              onPressed: _isLoading ? null : _detectPlant,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1FCFC5),
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
            if (_result != null) ...[
              const Text("Kết quả phân tích:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_result!['isHealthy'] == true)
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_result!['isHealthy'] == true)
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_result!['isHealthy'] == true)
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        (_result!['isHealthy'] == true)
                            ? Icons.check_circle_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: (_result!['isHealthy'] == true)
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _result!['diseaseName'] ?? 'Không rõ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: (_result!['isHealthy'] == true)
                                  ? Colors.green.shade800
                                  : Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Độ tin cậy: ${((_result!['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (_result!['isHealthy'] == true)
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  backgroundColor: const Color(0xFF1FCFC5),
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

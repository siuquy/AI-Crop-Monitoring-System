import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/service/report_service.dart';
import '../../core/service/api_client.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';

class CreateReportScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> analysisResult;
  final String farmId;
  final String plotId;
  final String bedId;

  const CreateReportScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
    required this.farmId,
    required this.plotId,
    required this.bedId,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;
  late Future<Map<String, String>> _locationNamesFuture;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.analysisResult['diseaseName']);
    _descriptionController =
        TextEditingController(text: widget.analysisResult['description']);
    _locationNamesFuture = _fetchLocationNames();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReportService.createReport(
        title: _titleController.text,
        description: _descriptionController.text,
        image: File(widget.imagePath),
        farmId: widget.farmId,
        plotId: widget.plotId,
        bedId: widget.bedId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo báo cáo thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Điều hướng về màn hình chính (hoặc màn hình gốc) sau khi tạo thành công.
      // Xóa tất cả các màn hình trên nó (Scan, CreateReport)
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo báo cáo mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationInfo(),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng xem lại và chỉnh sửa thông tin trước khi gửi báo cáo.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề báo cáo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text('Ảnh đính kèm:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.imagePath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send),
                label: const Text('Gửi báo cáo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
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
}

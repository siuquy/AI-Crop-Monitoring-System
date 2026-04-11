import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/service/report_service.dart';
import '../../core/service/api_client.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/season_detail_service.dart';

enum ReportSeverity { low, medium, high }

extension ReportSeverityExtension on ReportSeverity {
  String get displayName {
    switch (this) {
      case ReportSeverity.low:
        return 'Thấp';
      case ReportSeverity.medium:
        return 'Trung bình';
      case ReportSeverity.high:
        return 'Cao';
      default:
        return '';
    }
  }
}

class CreateReportScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> analysisResult;
  final String farmId;
  final String plotId;
  final String bedId;
  final String? seasonId;
  final String? ownerId;

  const CreateReportScreen({
    super.key,
    required this.imagePath,
    required this.analysisResult,
    required this.farmId,
    required this.plotId,
    required this.bedId,
    this.seasonId,
    this.ownerId,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;
  ReportSeverity _severity = ReportSeverity.medium;
  late Future<Map<String, String>> _locationNamesFuture;
  String? _resolvedSeasonId;

  @override
  void initState() {
    super.initState();

    // Lấy tên bệnh linh hoạt (bao gồm cả trường hợp AI dịch sang tiếng Việt)
    final plantName = widget.analysisResult['name'] ??
        widget.analysisResult['diseaseName'] ??
        widget.analysisResult['Tên bệnh'] ??
        '';

    _titleController = TextEditingController(text: plantName.toString());

    String aiDesc = widget.analysisResult['description']?.toString() ??
        widget.analysisResult['Description']?.toString() ??
        '';
    final symptoms = widget.analysisResult['symptoms'] as List<dynamic>? ?? [];
    final treatment =
        widget.analysisResult['treatment'] as List<dynamic>? ?? [];

    StringBuffer descBuffer = StringBuffer();
    if (aiDesc.trim().isNotEmpty) descBuffer.writeln(aiDesc.trim());
    if (symptoms.isNotEmpty) {
      descBuffer.writeln('\n* Triệu chứng:');
      for (var s in symptoms) descBuffer.writeln('  - $s');
    }
    if (treatment.isNotEmpty) {
      descBuffer.writeln('\n* Cách xử lý:');
      for (var t in treatment) descBuffer.writeln('  - $t');
    }

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
    widget.analysisResult.forEach((key, value) {
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

    _resolvedSeasonId = widget.seasonId;
    String finalDescription = descBuffer.toString().trim();
    if (finalDescription.isEmpty) {
      bool isHealthy = widget.analysisResult['isHealthy'] == true ||
          plantName.toString().toLowerCase().contains('khỏe mạnh');
      if (isHealthy) {
        finalDescription =
            'Cây trồng khỏe mạnh, không phát hiện dấu hiệu bất thường.';
      } else {
        finalDescription =
            'Đã phát hiện vấn đề trên cây trồng. Cần kiểm tra và xử lý thêm.';
      }
    }

    _descriptionController =
        TextEditingController(text: finalDescription.trim());
    _locationNamesFuture = _fetchLocationNames();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _fetchLocationNames() async {
    final results = await Future.wait([
      FarmService.getFarmMap(),
      PlotService.getPlotMap(),
      BedService.getBedMap(),
      SeasonDetailService.getSeasonDetailMap(),
    ]);

    final farmMap = results[0] as Map<String, String>;
    final plotMap = results[1] as Map<String, Map<String, dynamic>>;
    final bedMap = results[2] as Map<String, Map<String, dynamic>>;
    final seasonDetailMap = results[3] as Map<String, Map<String, dynamic>>;

    // Tự động tìm seasonId thông qua bedId nếu chưa được truyền vào
    if (_resolvedSeasonId == null) {
      for (var detail in seasonDetailMap.values) {
        if (detail['bedId']?.toString() == widget.bedId) {
          _resolvedSeasonId = detail['seasonId']?.toString();
          break;
        }
      }
    }

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
      // MẸO: Vì không được sửa Backend, ta sẽ "giấu" cục JSON này vào cuối description.
      // Khi tải về, Mobile sẽ tự bóc tách ra để hiển thị UI đẹp.
      final aiJsonString = jsonEncode(widget.analysisResult);
      final fullDescription =
          'Mức độ nghiêm trọng: ${_severity.displayName}\n\n${_descriptionController.text}\n\n---AI_RESULT_JSON---\n$aiJsonString';

      await ReportService.createReport(
        title: _titleController.text,
        description: fullDescription,
        image: File(widget.imagePath),
        plotId: widget.plotId,
        bedId: widget.bedId,
        aiResults: widget.analysisResult,
        seasonId: _resolvedSeasonId,
        ownerId: widget.ownerId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo báo cáo thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Sửa lỗi điều hướng: Quay lại màn hình trước đó (ví dụ: Chi tiết công việc)
      // bằng cách đóng 2 màn hình (CreateReportScreen và ScanResultScreen).
      int popCount = 0;
      Navigator.of(context).popUntil((_) => ++popCount > 2);
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
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thông tin báo cáo',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
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
                          hintText:
                              'Nhập mô tả tình trạng bệnh hoặc chọn gợi ý bên dưới...',
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildQuickSymptomChips(),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ReportSeverity>(
                        value: _severity,
                        decoration: const InputDecoration(
                          labelText: 'Mức độ nghiêm trọng',
                          border: OutlineInputBorder(),
                        ),
                        items: ReportSeverity.values
                            .map((ReportSeverity severity) {
                          return DropdownMenuItem<ReportSeverity>(
                            value: severity,
                            child: Text(severity.displayName),
                          );
                        }).toList(),
                        onChanged: (ReportSeverity? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _severity = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ảnh đính kèm',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
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
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Xóa ảnh và chụp lại',
                                  onPressed: () {
                                    // Quay lại màn hình quét (ScanResultScreen) để người dùng chọn "Thử ảnh khác"
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildQuickSymptomChips() {
    final List<String> commonSymptoms = [
      'Vàng lá',
      'Đốm đen',
      'Héo rũ',
      'Sâu ăn lá',
      'Thối rễ',
      'Phấn trắng',
      'Quăn mép lá'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gợi ý triệu chứng nhanh:',
            style: TextStyle(
                fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: commonSymptoms.map((symptom) {
            return ActionChip(
              label: Text(symptom, style: const TextStyle(fontSize: 13)),
              backgroundColor: Colors.teal.shade50,
              onPressed: () {
                final currentText = _descriptionController.text;
                if (currentText.isEmpty ||
                    currentText
                        .contains('Đã phát hiện vấn đề trên cây trồng')) {
                  _descriptionController.text = symptom;
                } else {
                  _descriptionController.text = '$currentText, $symptom';
                }
                _descriptionController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _descriptionController.text.length),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

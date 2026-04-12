import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../core/service/report_service.dart';
import '../../core/service/api_client.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/season_detail_service.dart';
import '../../ai_result_widget.dart';

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
  String _selectedReportType = 'DISEASE';
  final List<String> _reportTypes = ['DISEASE', 'ENVIRONMENT', 'PEST', 'OTHER'];
  String? _resolvedSeasonId;
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();

    final plantName = widget.analysisResult['name'] ??
        widget.analysisResult['diseaseName'] ??
        widget.analysisResult['Tên bệnh'] ??
        '';

    _imagePaths = [widget.imagePath]; // Khởi tạo với ảnh ban đầu từ AI

    _titleController = TextEditingController(text: plantName.toString());

    _resolvedSeasonId = widget.seasonId;
    String finalDescription = '';
    bool isHealthy = widget.analysisResult['isHealthy'] == true ||
        plantName.toString().toLowerCase().contains('khỏe mạnh');
    if (isHealthy) {
      finalDescription =
          'Cây trồng khỏe mạnh, không phát hiện dấu hiệu bất thường.';
    } else {
      finalDescription =
          'Đã phát hiện vấn đề trên cây trồng. Cần kiểm tra và xử lý thêm.';
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

  String _getReportTypeDisplayName(String type) {
    switch (type) {
      case 'DISEASE':
        return 'Sâu bệnh (Disease)';
      case 'ENVIRONMENT':
        return 'Môi trường (Environment)';
      case 'PEST':
        return 'Dịch hại/Côn trùng (Pest)';
      default:
        return 'Khác (Other)';
    }
  }

  Future<void> _pickAdditionalImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((e) => e.path));
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final fullDescription =
          'Mức độ nghiêm trọng: ${_severity.displayName}\n\n${_descriptionController.text}';
      final finalOwnerId =
          widget.ownerId ?? '4868dc1a-08f5-4bb9-a711-34961ddd4b85';

      await ReportService.createReport(
        title: _titleController.text,
        description: fullDescription,
        reportType: _selectedReportType,
        images: _imagePaths
            .map((path) => File(path))
            .toList(), // Truyền danh sách ảnh
        plotId: widget.plotId,
        bedId: widget.bedId,
        aiResults: widget.analysisResult,
        seasonId: _resolvedSeasonId,
        ownerId: finalOwnerId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo báo cáo thành công!'),
          backgroundColor: Colors.green,
        ),
      );

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
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text('Tạo báo cáo mới',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
              _buildImageSection(),
              const SizedBox(height: 16),
              _buildAiResultSection(),
              const SizedBox(height: 16),
              _buildFormSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.location_on_rounded,
                    color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khu vực ghi nhận',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${names['farmName']} - ${names['plotName']} - ${names['bedName']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hình ảnh đính kèm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagePaths.length + 1,
              itemBuilder: (context, index) {
                if (index == _imagePaths.length) {
                  return GestureDetector(
                    onTap: _pickAdditionalImages,
                    child: Container(
                      width: 90,
                      margin:
                          const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                            style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              color: Colors.grey.shade600, size: 28),
                          const SizedBox(height: 4),
                          Text('Thêm ảnh',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      margin: const EdgeInsets.only(
                          right: 12.0, top: 4.0, bottom: 4.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                        image: DecorationImage(
                          image: FileImage(File(_imagePaths[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (index > 0)
                      Positioned(
                        right: 4,
                        top: -4,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                          onPressed: () {
                            setState(() {
                              _imagePaths.removeAt(index);
                            });
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResultSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.auto_awesome_rounded,
                    color: Colors.purple.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Kết quả phân tích AI',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: AiResultWidget(aiData: widget.analysisResult),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nội dung báo cáo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration:
                _inputDecoration('Tiêu đề báo cáo', Icons.title_rounded),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tiêu đề';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedReportType,
            decoration:
                _inputDecoration('Loại báo cáo', Icons.category_rounded),
            items: _reportTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(_getReportTypeDisplayName(type)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedReportType = newValue;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReportSeverity>(
            value: _severity,
            decoration:
                _inputDecoration('Mức độ nghiêm trọng', Icons.warning_rounded),
            items: ReportSeverity.values.map((ReportSeverity severity) {
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration:
                _inputDecoration('Ghi chú thêm', Icons.description_rounded)
                    .copyWith(
              alignLabelWithHint: true,
              hintText: 'Nhập tình trạng thực tế...',
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập ghi chú';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildQuickSymptomChips(),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade400, width: 1.5),
      ),
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
        const Text('Gợi ý nhập nhanh:',
            style: TextStyle(
                fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: commonSymptoms.map((symptom) {
            return ActionChip(
              label: Text(symptom,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.w500)),
              backgroundColor: Colors.teal.shade50,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
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

  Widget _buildSubmitButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4))
          ],
        ),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Gửi báo cáo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
      ),
    );
  }
}

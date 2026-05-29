import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/report_service.dart';
import '../../core/service/api_client.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/season_service.dart';
import '../../shared/ai_result_widget.dart';
import '../../core/service/worker_service.dart';
import '../../core/service/iot_service.dart';
import '../../models/iot_device.dart';
import '../../models/iot_data.dart';
import '../../models/worker.dart';

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
  String _selectedReportType = 'DISEASE';
  final List<String> _reportTypes = ['DISEASE', 'ENVIRONMENT', 'PEST', 'OTHER'];
  List<String> _imagePaths = [];

  bool _isLoadingIotData = false;
  IotData? _latestIotData;
  IotDevice? _associatedDevice;

  bool _isLoadingData = true;
  Map<String, String> _farmMap = {};
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, Map<String, dynamic>> _bedMap = {};
  Map<String, Map<String, dynamic>> _seasonMap = {};
  List<Worker> _owners = [];
  Map<String, String> _seasonOptions = {};

  String? _selectedFarmId;
  String? _selectedPlotId;
  String? _selectedBedId;
  String? _selectedSeasonId;
  String? _selectedOwnerId;

  @override
  void initState() {
    super.initState();

    final plantName = widget.analysisResult['disease']?.toString() ?? '';

    _imagePaths = [widget.imagePath]; // Khởi tạo với ảnh ban đầu từ AI

    _titleController = TextEditingController(text: plantName);

    // Lấy description từ AI để gán thẳng vào khung Mô tả chi tiết cho người dùng chỉnh sửa
    String aiDescription =
        widget.analysisResult['description']?.toString() ?? '';

    if (widget.analysisResult['symptoms'] != null &&
        widget.analysisResult['symptoms'] is List) {
      aiDescription += '\n\nTriệu chứng:\n- ' +
          (widget.analysisResult['symptoms'] as List).join('\n- ');
    }

    final solutions = widget.analysisResult['solutions'] as List? ?? [];
    final treatmentSteps =
        widget.analysisResult['treatmentSteps'] as List? ?? [];
    final combinedTreatment = [...solutions, ...treatmentSteps];
    if (combinedTreatment.isNotEmpty) {
      aiDescription +=
          '\n\nKhuyến nghị / Giải pháp:\n- ' + combinedTreatment.join('\n- ');
    }

    _descriptionController = TextEditingController(text: aiDescription.trim());

    _selectedFarmId = widget.farmId.isNotEmpty ? widget.farmId : null;
    _selectedPlotId = widget.plotId.isNotEmpty ? widget.plotId : null;
    _selectedBedId = widget.bedId.isNotEmpty ? widget.bedId : null;
    _selectedSeasonId =
        widget.seasonId?.isNotEmpty == true ? widget.seasonId : null;
    _selectedOwnerId =
        widget.ownerId?.isNotEmpty == true ? widget.ownerId : null;

    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FarmService.getFarmMap(),
        PlotService.getPlotMap(),
        BedService.getBedMap(),
        SeasonService.getSeasonMap(),
      ]);

      _farmMap = results[0] as Map<String, String>;
      _plotMap = results[1] as Map<String, Map<String, dynamic>>;
      _bedMap = results[2] as Map<String, Map<String, dynamic>>;
      _seasonMap = results[3] as Map<String, Map<String, dynamic>>;

      // Tạm thời set cứng Owner vì Worker không gọi được API Staff (Lỗi 404/403)
      _owners = [
        Worker(
          id: widget.ownerId ??
              '4868dc1a-08f5-4bb9-a711-34961ddd4b85', // Có thể đổi lại ID thật nếu bạn muốn
          fullName: 'Chủ Trang Trại (Mặc định)',
          role: 'Owner',
          email: '',
        )
      ];

      for (var detail in _seasonMap.values) {
        final sId = detail['seasonId']?.toString();
        if (sId != null) {
          final seasonName = detail['seasonName']?.toString() ?? 'Mùa vụ $sId';
          _seasonOptions[sId] = seasonName;
        }
      }

      // --- Xử lý đồng bộ ID (Fix lỗi trống data do sai khác chữ hoa/thường) ---
      String? findKey(Iterable<String> keys, String? target) {
        if (target == null || target.isEmpty) return null;
        try {
          return keys
              .firstWhere((k) => k.toLowerCase() == target.toLowerCase());
        } catch (_) {
          return null;
        }
      }

      _selectedFarmId = findKey(_farmMap.keys, _selectedFarmId);
      _selectedPlotId = findKey(_plotMap.keys, _selectedPlotId);
      _selectedBedId = findKey(_bedMap.keys, _selectedBedId);

      // Tự động chọn mùa vụ đầu tiên thuộc trang trại đang chọn nếu chưa có
      if (_selectedSeasonId == null && _selectedFarmId != null) {
        for (var detail in _seasonMap.values) {
          if (detail['farmId']?.toString().toLowerCase() ==
              _selectedFarmId?.toLowerCase()) {
            _selectedSeasonId = detail['seasonId']?.toString();
            break;
          }
        }
      }
      _selectedSeasonId = findKey(_seasonOptions.keys, _selectedSeasonId);

      // Tự động gán Owner đầu tiên (vì luồng Worker chỉ gửi cho Owner)
      if (_selectedOwnerId == null && _owners.isNotEmpty) {
        _selectedOwnerId = _owners.first.id;
      }

      _loadIotDataForBed();
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu dropdown: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _loadIotDataForBed() async {
    if (_selectedBedId == null) return;

    setState(() {
      _isLoadingIotData = true;
      _latestIotData = null;
      _associatedDevice = null;
    });

    try {
      // Tìm thiết bị theo BedId thông qua API IotDevices
      final deviceRes =
          await ApiClient.instance.get('/api/IotDevices?bedId=$_selectedBedId');

      if (deviceRes != null &&
          deviceRes['success'] == true &&
          deviceRes['data'] != null) {
        final data = deviceRes['data'];
        if (data is List && data.isNotEmpty) {
          _associatedDevice =
              IotDevice.fromJson(data.first as Map<String, dynamic>);
        } else if (data is Map<String, dynamic>) {
          _associatedDevice = IotDevice.fromJson(data);
        }

        // Lấy dữ liệu Iot Data thông qua DeviceId
        if (_associatedDevice != null &&
            _associatedDevice!.deviceId.isNotEmpty) {
          final dataRes = await ApiClient.instance
              .get('/api/IotDatas?deviceId=${_associatedDevice!.deviceId}');
          if (dataRes != null &&
              dataRes['success'] == true &&
              dataRes['data'] != null) {
            final dData = dataRes['data'];
            List<IotData> parsedDatas = [];
            if (dData is List) {
              parsedDatas = dData
                  .map((d) => IotData.fromJson(d as Map<String, dynamic>))
                  .toList();
            } else if (dData is Map<String, dynamic>) {
              parsedDatas = [IotData.fromJson(dData)];
            }

            if (parsedDatas.isNotEmpty) {
              parsedDatas.sort((a, b) => (b.recordedAt ?? DateTime(0))
                  .compareTo(a.recordedAt ?? DateTime(0)));
              _latestIotData = parsedDatas.first;
            }
          }
        }
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404) {
        debugPrint('Lỗi API tải dữ liệu IoT: $e');
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu IoT: $e');
    } finally {
      if (mounted) setState(() => _isLoadingIotData = false);
    }
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
      final fullDescription = _descriptionController.text.trim();
      await ReportService.createReport(
        title: _titleController.text,
        description: fullDescription,
        reportType: _selectedReportType,
        images: _imagePaths
            .map((path) => File(path))
            .toList(), // Truyền danh sách ảnh
        diseaseName: widget.analysisResult['disease']?.toString(),
        plotId: _selectedPlotId,
        bedId: _selectedBedId,
        aiResults: widget.analysisResult,
        seasonId: _selectedSeasonId,
        ownerId: _selectedOwnerId,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tạo báo cáo mới',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormSection(),
              const SizedBox(height: 16),
              _buildDropdownSection(),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 16),
              _buildAiResultSection(),
              const SizedBox(height: 16),
              _buildIotSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildDropdownSection() {
    if (_isLoadingData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final availablePlots = _plotMap.entries
        .where((e) =>
            _selectedFarmId == null ||
            e.value['farmId']?.toString().toLowerCase() ==
                _selectedFarmId?.toLowerCase())
        .toList();

    final availableBeds = _bedMap.entries
        .where((e) =>
            _selectedPlotId == null ||
            e.value['plotId']?.toString().toLowerCase() ==
                _selectedPlotId?.toLowerCase())
        .toList();

    final farmName = _farmMap[_selectedFarmId] ?? 'Chưa xác định';
    final plotName = availablePlots.any((p) => p.key == _selectedPlotId)
        ? availablePlots
                .firstWhere((p) => p.key == _selectedPlotId)
                .value['plotName']
                ?.toString() ??
            'Chưa xác định'
        : 'Chưa xác định';
    final bedName = availableBeds.any((b) => b.key == _selectedBedId)
        ? availableBeds
                .firstWhere((b) => b.key == _selectedBedId)
                .value['bedName']
                ?.toString() ??
            'Chưa xác định'
        : 'Chưa xác định';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin liên quan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Thẻ thông tin Vị trí (Chỉ đọc)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Column(
              children: [
                _buildReadOnlyRow(
                    Icons.agriculture_rounded, 'Trang trại', farmName),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.black12)),
                _buildReadOnlyRow(Icons.map_rounded, 'Khu vực', plotName),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.black12)),
                _buildReadOnlyRow(Icons.grass_rounded, 'Luống', bedName),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _seasonOptions.containsKey(_selectedSeasonId)
                ? _selectedSeasonId
                : null,
            decoration: _inputDecoration(
                'Mùa vụ (Season)', Icons.calendar_month_rounded),
            items: _seasonOptions.entries
                .map((e) => DropdownMenuItem<String>(
                    value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedSeasonId = val;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal.shade700),
        const SizedBox(width: 12),
        Text('$label:',
            style: TextStyle(fontSize: 14, color: Colors.teal.shade900)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
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

  Widget _buildIotSection() {
    if (_isLoadingIotData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_latestIotData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sensors_rounded,
                        color: Colors.blue.shade600, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Dữ liệu môi trường',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                tooltip: 'Thêm vào mô tả',
                onPressed: () {
                  final appendText =
                      '\n\n--- Dữ liệu IoT ---\nNhiệt độ: ${_latestIotData!.temperature}°C\nĐộ ẩm: ${_latestIotData!.humidity}%\nĐộ ẩm đất: ${_latestIotData!.soilMoisture}%';
                  setState(() {
                    _descriptionController.text =
                        _descriptionController.text + appendText;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Đã đính kèm dữ liệu IoT vào mô tả'),
                      backgroundColor: Colors.green));
                },
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIotMetric(
                  Icons.thermostat,
                  '${_latestIotData!.temperature}°C',
                  'Nhiệt độ',
                  Colors.orange),
              _buildIotMetric(Icons.water_drop, '${_latestIotData!.humidity}%',
                  'Độ ẩm', Colors.blue),
              _buildIotMetric(Icons.grass, '${_latestIotData!.soilMoisture}%',
                  'Ẩm đất', Colors.brown),
            ],
          ),
          if (_associatedDevice != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_associatedDevice!.name} • ${_latestIotData!.recordedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(_latestIotData!.recordedAt!.toLocal()) : 'N/A'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildIotMetric(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color.withOpacity(0.9))),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
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
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
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
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/service/bed_service.dart';
import '../../core/service/crop_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final String? selectedFarmId;
  final String? selectedPlotId;
  final String? selectedBedId;

  const ReportDetailScreen({
    super.key,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    this.selectedFarmId,
    this.selectedPlotId,
    this.selectedBedId,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _farms = [];
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, Map<String, dynamic>> _bedMap = {};
  Map<String, String> _cropMap = {}; // cropId → cropName

  List<Map<String, dynamic>> _filteredPlots = [];
  List<Map<String, dynamic>> _filteredBeds = [];

  String? _selectedFarmId;
  String? _selectedPlotId;
  String? _selectedBedId;

  String? _selectedCropId;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text =
        'Phát hiện các đốm vàng nâu trên lá ${widget.diseaseName}, '
        'tập trung chủ yếu ở phần ngọn. Có dấu hiệu lan rộng nhanh...';
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        FarmService.getFarmMap(),
        PlotService.getPlotMap(),
        BedService.getBedMap(),
        CropService.getCropMap(),
      ]);

      final farmMap = (results[0] as Map).cast<String, String>();
      final farms = farmMap.entries
          .map((e) => {'farmId': e.key, 'farmName': e.value})
          .toList();
      final plotMap = (results[1] as Map).cast<String, Map<String, dynamic>>();
      final bedMap = (results[2] as Map).cast<String, Map<String, dynamic>>();
      final cropMap = (results[3] as Map).cast<String, String>();

      setState(() {
        _farms = farms;
        _plotMap = plotMap;
        _bedMap = bedMap;
        _cropMap = cropMap;

        // Auto-select first crop
        if (_cropMap.isNotEmpty) {
          _selectedCropId = _cropMap.keys.first;
        }

        // Use passed-in farm ID or default to the first one
        if (widget.selectedFarmId != null &&
            _farms.any((f) => f['farmId'] == widget.selectedFarmId)) {
          _selectedFarmId = widget.selectedFarmId;
        } else if (_farms.isNotEmpty) {
          _selectedFarmId = _farms.first['farmId'];
        }
        _updateFilteredPlots(isInitialLoad: true);

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _updateFilteredPlots({bool isInitialLoad = false}) {
    _filteredPlots = _plotMap.entries
        .where(
            (e) => e.value['farmId']?.toString() == _selectedFarmId?.toString())
        .map((e) => {'plotId': e.key, 'plotName': e.value['plotName']})
        .toList();

    if (isInitialLoad &&
        widget.selectedPlotId != null &&
        _filteredPlots.any((p) => p['plotId'] == widget.selectedPlotId)) {
      _selectedPlotId = widget.selectedPlotId;
    } else {
      _selectedPlotId =
          _filteredPlots.isNotEmpty ? _filteredPlots.first['plotId'] : null;
    }
    _updateFilteredBeds(isInitialLoad: isInitialLoad);
  }

  void _updateFilteredBeds({bool isInitialLoad = false}) {
    _filteredBeds = _bedMap.entries
        .where((e) => e.value['plotId'].toString() == _selectedPlotId)
        .map((e) => {'bedId': e.key, 'bedName': e.value['bedName']})
        .toList();

    if (isInitialLoad &&
        widget.selectedBedId != null &&
        _filteredBeds.any((b) => b['bedId'] == widget.selectedBedId)) {
      _selectedBedId = widget.selectedBedId;
    } else {
      _selectedBedId =
          _filteredBeds.isNotEmpty ? _filteredBeds.first['bedId'] : null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  String get _selectedFarmName =>
      _farms.firstWhere(
        (f) => f['farmId'] == _selectedFarmId,
        orElse: () => {'farmName': ''},
      )['farmName'] ??
      '';

  String get _selectedPlotName =>
      _filteredPlots.firstWhere(
        (p) => p['plotId'] == _selectedPlotId,
        orElse: () => {'plotName': ''},
      )['plotName'] ??
      '';

  String get _selectedBedName =>
      _filteredBeds.firstWhere(
        (b) => b['bedId'] == _selectedBedId,
        orElse: () => {'bedName': ''},
      )['bedName'] ??
      '';

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tạo Báo cáo Công việc',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FCFC5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề báo cáo ──────────────────────────────────────────────
          _label('Tiêu đề báo cáo *'),
          _inputBox(
            child: Text(
              'Bệnh ${widget.diseaseName} - $_selectedPlotName',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),

          // ── Trang trại ───────────────────────────────────────────────────
          _label('Trang trại *'),
          _buildFarmDropdown(),
          const SizedBox(height: 16),

          // ── Khu + Luống ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Ruộng *'),
                    _buildPlotDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Luống *'),
                    _buildBedDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Loại cây trồng ────────────────────────────────────────────────
          _label('Loại cây trồng'),
          _buildCropDropdown(),
          const SizedBox(height: 16),

          // ── Mô tả hiện trạng ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('Mô tả hiện trạng'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✨ AI gợi ý',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1FCFC5)),
                ),
              ),
            ],
          ),
          _textArea(_descriptionController),
          const SizedBox(height: 16),

          // ── Ghi chú ──────────────────────────────────────────────────────
          _label('Ghi chú'),
          _textArea(_noteController, hint: 'Thêm ghi chú bổ sung...'),
          const SizedBox(height: 16),

          // ── Hình ảnh đính kèm ────────────────────────────────────────────
          _label('Hình ảnh đính kèm'),
          const SizedBox(height: 8),
          Row(
            children: [
              _imagePreview(widget.imagePath, true),
              const SizedBox(width: 12),
              _imagePreview(widget.imagePath, false),
              const SizedBox(width: 12),
              _addImageBox(),
            ],
          ),
          const SizedBox(height: 32),

          // ── Submit ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1FCFC5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _onSubmit,
              child: const Text(
                'Gửi báo cáo ➜',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dropdowns từ API ─────────────────────────────────────────────────────────

  Widget _buildFarmDropdown() {
    if (_farms.isEmpty) return _emptyDropdown('Không có trang trại');
    return _dropdownContainer(
      child: DropdownButton<String>(
        value: _selectedFarmId,
        isExpanded: true,
        underline: const SizedBox(),
        items: _farms
            .map((f) => DropdownMenuItem(
                  value: f['farmId'] as String,
                  child: Text(f['farmName'] as String),
                ))
            .toList(),
        onChanged: (v) => setState(() {
          _selectedFarmId = v;
          _updateFilteredPlots(); // isInitialLoad defaults to false
        }),
      ),
    );
  }

  Widget _buildPlotDropdown() {
    if (_filteredPlots.isEmpty) return _emptyDropdown('Không có khu');
    return _dropdownContainer(
      child: DropdownButton<String>(
        value: _selectedPlotId,
        isExpanded: true,
        underline: const SizedBox(),
        items: _filteredPlots
            .map((p) => DropdownMenuItem(
                  value: p['plotId'] as String,
                  child: Text(p['plotName'] as String),
                ))
            .toList(),
        onChanged: (v) => setState(() {
          _selectedPlotId = v;
          _updateFilteredBeds(); // isInitialLoad defaults to false
        }),
      ),
    );
  }

  Widget _buildBedDropdown() {
    if (_filteredBeds.isEmpty) return _emptyDropdown('Không có luống');
    return _dropdownContainer(
      child: DropdownButton<String>(
        value: _selectedBedId,
        isExpanded: true,
        underline: const SizedBox(),
        items: _filteredBeds
            .map((b) => DropdownMenuItem(
                  value: b['bedId'] as String,
                  child: Text(b['bedName'] as String),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedBedId = v),
      ),
    );
  }

  Widget _buildCropDropdown() {
    if (_cropMap.isEmpty) return _emptyDropdown('Không có loại cây');
    return _dropdownContainer(
      child: DropdownButton<String>(
        value: _selectedCropId,
        isExpanded: true,
        underline: const SizedBox(),
        items: _cropMap.entries
            .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedCropId = v),
      ),
    );
  }

  Widget _staticDropdown(
      {required String value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return _dropdownContainer(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _emptyDropdown(String hint) {
    return _dropdownContainer(
      child: Text(hint, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: _boxDecoration(),
      child: child,
    );
  }

  // ─── Submit ───────────────────────────────────────────────────────────────────
  void _onSubmit() {
    if (_selectedFarmId == null ||
        _selectedPlotId == null ||
        _selectedBedId == null ||
        _selectedCropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Vui lòng chọn đầy đủ trang trại, khu, luống và loại cây')),
      );
      return;
    }

    // TODO: gọi API POST /api/Reports tại đây với payload:
    // {
    //   farmId: _selectedFarmId,
    //   plotId: _selectedPlotId,
    //   bedId: _selectedBedId,
    //   cropId: _selectedCropId,
    //   description: _descriptionController.text,
    //   note: _noteController.text,
    //   diseaseName: widget.diseaseName,
    //   confidence: widget.confidence,
    //   imagePath: widget.imagePath,
    // }

    Navigator.pop(context);
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: child,
    );
  }

  Widget _textArea(TextEditingController controller, {String? hint}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration.collapsed(hintText: hint),
      ),
    );
  }

  Widget _imagePreview(String path, bool isDetected) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        if (isDetected)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Đã phân tích',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _addImageBox() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.add_a_photo, color: Colors.grey),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    );
  }
}

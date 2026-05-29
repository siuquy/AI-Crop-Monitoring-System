import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/season_service.dart';
import '../../core/service/harvest_service.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class CreateHarvestScreen extends StatefulWidget {
  final String? initialPlotId;
  final String? initialSeasonId;
  final String? initialCropName;

  const CreateHarvestScreen({
    super.key,
    this.initialPlotId,
    this.initialSeasonId,
    this.initialCropName,
  });

  @override
  State<CreateHarvestScreen> createState() => _CreateHarvestScreenState();
}

class _CreateHarvestScreenState extends State<CreateHarvestScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cropNameController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;

  String _selectedUnit = 'kg';
  String _selectedQuality = 'Tốt';
  DateTime _harvestDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _units = ['kg', 'tấn', 'củ', 'quả', 'bó'];
  final List<String> _qualities = ['Tốt', 'Khá', 'Trung bình', 'Kém'];

  bool _isLoadingData = true;
  Map<String, String> _farmMap = {};
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, Map<String, dynamic>> _seasonMap = {};

  String? _selectedFarmId;
  String? _selectedPlotId;
  String? _selectedSeasonId;

  @override
  void initState() {
    super.initState();
    _cropNameController =
        TextEditingController(text: widget.initialCropName ?? '');
    _quantityController = TextEditingController();
    _notesController = TextEditingController();

    _selectedPlotId = widget.initialPlotId;
    _selectedSeasonId = widget.initialSeasonId;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FarmService.getFarmMap(),
        PlotService.getPlotMap(),
        SeasonService.getSeasonMap(),
      ]);

      _farmMap = results[0] as Map<String, String>;
      _plotMap = results[1] as Map<String, Map<String, dynamic>>;
      _seasonMap = results[2] as Map<String, Map<String, dynamic>>;

      String? findKey(Iterable<String> keys, String? target) {
        if (target == null || target.isEmpty) return null;
        try {
          return keys
              .firstWhere((k) => k.toLowerCase() == target.toLowerCase());
        } catch (_) {
          return null;
        }
      }

      _selectedPlotId = findKey(_plotMap.keys, _selectedPlotId);
      _selectedSeasonId = findKey(_seasonMap.keys, _selectedSeasonId);

      if (_selectedPlotId != null && _plotMap.containsKey(_selectedPlotId)) {
        final farmIdFromPlot = _plotMap[_selectedPlotId]!['farmId']?.toString();
        _selectedFarmId = findKey(_farmMap.keys, farmIdFromPlot);
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu dropdown: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black87, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await HarvestService.submitHarvest(
      plotId: _selectedPlotId ?? '',
      seasonId: _selectedSeasonId ?? '',
      cropName: _cropNameController.text.trim(),
      quantity: double.tryParse(_quantityController.text.trim()) ?? 0.0,
      unit: _selectedUnit,
      quality: _selectedQuality,
      harvestDate: _harvestDate.toUtc(),
      notes: _notesController.text.trim(),
      image: _selectedImage,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tạo thu hoạch thành công!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Trả về true để reload danh sách
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lỗi khi tạo thu hoạch, vui lòng thử lại!'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePlots = _plotMap.entries
        .where((e) =>
            _selectedFarmId == null ||
            e.value['farmId']?.toString().toLowerCase() ==
                _selectedFarmId?.toLowerCase())
        .toList();

    final availableSeasons = _seasonMap.entries
        .where((e) =>
            _selectedFarmId == null ||
            e.value['farmId']?.toString().toLowerCase() ==
                _selectedFarmId?.toLowerCase())
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Tạo Thu Hoạch',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopHeader(),
                    _buildSectionContainer(
                      title: 'Thông tin chung',
                      icon: Icons.info_outline_rounded,
                      child: Column(
                        children: [
                          if (_isLoadingData)
                            const Center(
                                child: CircularProgressIndicator(
                                    color: primaryTeal))
                          else ...[
                            DropdownButtonFormField<String>(
                              value: _farmMap.containsKey(_selectedFarmId)
                                  ? _selectedFarmId
                                  : null,
                              decoration: _dropdownDecoration(
                                  'Trang trại', Icons.agriculture_outlined),
                              items: _farmMap.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedFarmId = val;
                                  _selectedPlotId = null;
                                  _selectedSeasonId = null;
                                });
                              },
                              validator: (val) => val == null
                                  ? 'Bắt buộc chọn trang trại'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedPlotId != null &&
                                      availablePlots
                                          .any((p) => p.key == _selectedPlotId)
                                  ? _selectedPlotId
                                  : null,
                              decoration: _dropdownDecoration(
                                  'Khu vực (Plot)', Icons.location_on_outlined),
                              items: availablePlots
                                  .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                          e.value['plotName']?.toString() ??
                                              'Khu vực ${e.key}')))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedPlotId = val),
                              validator: (val) =>
                                  val == null ? 'Bắt buộc chọn khu vực' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedSeasonId != null &&
                                      availableSeasons.any(
                                          (s) => s.key == _selectedSeasonId)
                                  ? _selectedSeasonId
                                  : null,
                              decoration: _dropdownDecoration('Mùa vụ (Season)',
                                  Icons.calendar_month_outlined),
                              items: availableSeasons
                                  .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                          e.value['seasonName']?.toString() ??
                                              'Mùa vụ ${e.key}')))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedSeasonId = val),
                              validator: (val) =>
                                  val == null ? 'Bắt buộc chọn mùa vụ' : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _cropNameController,
                            label: 'Tên cây trồng',
                            icon: Icons.eco_outlined,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Bắt buộc nhập tên cây trồng'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionContainer(
                      title: 'Chi tiết thu hoạch',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _quantityController,
                                  label: 'Sản lượng',
                                  icon: Icons.scale_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  validator: (val) {
                                    if (val == null || val.isEmpty)
                                      return 'Nhập SL';
                                    if (double.tryParse(val) == null)
                                      return 'Không hợp lệ';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  decoration: InputDecoration(
                                    labelText: 'Đơn vị',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 16),
                                  ),
                                  items: _units
                                      .map((e) => DropdownMenuItem(
                                          value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedUnit = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedQuality,
                            decoration: InputDecoration(
                              labelText: 'Chất lượng',
                              prefixIcon: const Icon(Icons.star_border_rounded,
                                  color: primaryTeal),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                            ),
                            items: _qualities
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedQuality = val!),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event, color: primaryTeal),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Ngày thu hoạch',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600)),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(_harvestDate),
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.edit_calendar,
                                      color: Colors.grey.shade400),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionContainer(
                      title: 'Hình ảnh & Ghi chú',
                      icon: Icons.photo_camera_back_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt,
                                            color: primaryTeal),
                                        title: const Text('Chụp ảnh mới'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library,
                                            color: primaryTeal),
                                        title: const Text('Chọn từ thư viện'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.gallery);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: primaryTeal.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: primaryTeal.withOpacity(0.3),
                                    width: 1.5),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(_selectedImage!,
                                          fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: primaryTeal.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 28,
                                              color: primaryTeal),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('Thêm ảnh minh chứng',
                                            style: TextStyle(
                                                color: primaryTeal
                                                    .withOpacity(0.8),
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _notesController,
                            label: 'Ghi chú thêm',
                            icon: Icons.notes,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Lưu Thu Hoạch',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: primaryTeal.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo Thu Hoạch',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ghi nhận thông tin, sản lượng và chất lượng của đợt thu hoạch mới.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryTeal, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType ??
          (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: primaryTeal) : null,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryTeal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
    );
  }
}

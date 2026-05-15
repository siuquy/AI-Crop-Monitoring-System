import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/service/harvest_service.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color darkTeal = Color(0xFF388E3C);
const Color bgColor = Color(0xFFF0F8F1);

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  File? _image;

  Map<String, dynamic>? _selectedHarvest;
  String _quantity = '';
  String _selectedUnit = 'kg';
  String _selectedQuality = 'Good';
  DateTime _harvestDate = DateTime.now();
  String _notes = '';

  List<Map<String, dynamic>> _harvests = [];
  bool _isLoadingHarvests = true;

  @override
  void initState() {
    super.initState();
    _loadHarvests();
  }

  Future<void> _loadHarvests() async {
    try {
      final data = await HarvestService.getHarvests();
      if (mounted) {
        setState(() {
          // Lọc ra các kế hoạch thu hoạch chưa hoàn thành
          _harvests = data.where((h) => h['status'] != 'completed').toList();
          _isLoadingHarvests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHarvests = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _harvestDate) {
      setState(() {
        _harvestDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận gửi'),
        content: const Text('Bạn có chắc chắn muốn ghi nhận thu hoạch này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await HarvestService.submitHarvest(
        plotId: _selectedHarvest?['plotId'] ?? '',
        seasonId: _selectedHarvest?['seasonId'] ?? '',
        cropName: _selectedHarvest?['cropName'] ?? '',
        quantity: double.tryParse(_quantity) ?? 0,
        unit: _selectedUnit,
        quality: _selectedQuality,
        harvestDate: _harvestDate,
        notes: _notes,
        image: _image,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ghi nhận thu hoạch thành công!'),
                backgroundColor: primaryTeal),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    const Text('Không thể lưu thông tin. Vui lòng thử lại.'),
                backgroundColor: Colors.red.shade700),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red.shade700),
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Ghi nhận Thu hoạch',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                title: 'Thông tin chung',
                icon: Icons.info_outline,
                child: Column(
                  children: [
                    _isLoadingHarvests
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: primaryTeal))
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey.shade600),
                            decoration: _inputDecoration('Kế hoạch thu hoạch',
                                Icons.assignment_outlined),
                            value: _selectedHarvest,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            items: _harvests.map((h) {
                              final label =
                                  '${h['cropName']} - ${h['plotName']} (${h['seasonName']})';
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: h,
                                child: Text(label,
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedHarvest = val),
                            validator: (val) =>
                                val == null ? 'Vui lòng chọn kế hoạch' : null,
                          ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: ValueKey(_selectedHarvest?['cropName'] ?? ''),
                      initialValue: _selectedHarvest?['cropName'] ?? '',
                      readOnly: true,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(
                              'Tên giống / Cây trồng', Icons.eco_outlined)
                          .copyWith(
                        fillColor: Colors.grey.shade100,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng chọn kế hoạch ở trên'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Chi tiết thu hoạch',
                icon: Icons.shopping_basket_outlined,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration: _inputDecoration(
                                'Sản lượng', Icons.monitor_weight_outlined),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            onSaved: (val) => _quantity = val ?? '0',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Bắt buộc';
                              }
                              if (double.tryParse(val) == null) {
                                return 'Phải là số';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey.shade600),
                            decoration: _inputDecoration(
                                'Đơn vị', Icons.category_outlined),
                            value: _selectedUnit,
                            style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            items: ['kg', 'ton', 'basket'].map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child:
                                    Text(unit, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedUnit = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade600),
                      decoration: _inputDecoration(
                          'Chất lượng', Icons.verified_outlined),
                      value: _selectedQuality,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      items: [
                        {'id': 'Good', 'name': 'Tốt (Good)'},
                        {'id': 'Medium', 'name': 'Trung bình (Medium)'},
                        {'id': 'Bad', 'name': 'Kém (Bad)'},
                      ].map((q) {
                        return DropdownMenuItem<String>(
                          value: q['id']!,
                          child:
                              Text(q['name']!, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedQuality = val!),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: IgnorePointer(
                        child: TextFormField(
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                          decoration: _inputDecoration(
                              'Ngày thu hoạch', Icons.calendar_today_outlined),
                          controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy').format(_harvestDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: 'Hình ảnh & Ghi chú',
                icon: Icons.photo_camera_back_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: _inputDecoration(
                          'Ghi chú thêm...', Icons.edit_note_outlined),
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 15),
                      maxLines: 3,
                      onSaved: (val) => _notes = val ?? '',
                    ),
                    const SizedBox(height: 16),
                    if (_image != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => setState(() => _image = null),
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Máy ảnh'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: darkTeal,
                              side: const BorderSide(color: primaryTeal),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Thư viện'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: darkTeal,
                              side: const BorderSide(color: primaryTeal),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 6,
                    shadowColor: primaryTeal.withOpacity(0.5),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryTeal, darkTeal],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Ghi nhận Thu hoạch',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: darkTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
      prefixIcon: Icon(icon, color: primaryTeal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryTeal.withOpacity(0.5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

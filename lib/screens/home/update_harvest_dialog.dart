import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/harvest_service.dart';

const Color primaryTeal = Color(0xFF4CAF50);

class UpdateHarvestDialog extends StatefulWidget {
  final String harvestId;
  final DateTime? initialDate;
  final double initialQuantity;
  final String initialUnit;
  final String initialStatus;
  final String initialNotes;

  const UpdateHarvestDialog({
    super.key,
    required this.harvestId,
    this.initialDate,
    required this.initialQuantity,
    required this.initialUnit,
    required this.initialStatus,
    required this.initialNotes,
  });

  @override
  State<UpdateHarvestDialog> createState() => _UpdateHarvestDialogState();
}

class _UpdateHarvestDialogState extends State<UpdateHarvestDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _notesController;

  late DateTime _expectedDate;
  late String _selectedUnit;
  late String _selectedStatus;
  bool _isLoading = false;

  final List<String> _units = ['kg', 'tấn', 'củ', 'quả', 'bó'];
  final Map<String, String> _statuses = {
    'pending': 'Đang chờ',
    'in-progress': 'Đang thu hoạch',
    'completed': 'Hoàn thành',
  };

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.initialQuantity.toString());
    _notesController = TextEditingController(text: widget.initialNotes);
    _expectedDate = widget.initialDate ?? DateTime.now();
    _selectedUnit =
        _units.contains(widget.initialUnit) ? widget.initialUnit : _units.first;
    _selectedStatus = _statuses.containsKey(widget.initialStatus)
        ? widget.initialStatus
        : 'pending';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _expectedDate) {
      setState(() {
        _expectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await HarvestService.updateHarvest(
      harvestId: widget.harvestId,
      expectedDate: _expectedDate,
      expectedQuantity: double.tryParse(_quantityController.text.trim()) ?? 0,
      unit: _selectedUnit,
      status: _selectedStatus,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thu hoạch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
            context, true); // Trả về true để màn hình danh sách load lại
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thất bại, vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label,
      {IconData? prefixIcon, IconData? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: primaryTeal, size: 20)
          : null,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: Colors.grey.shade400, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cập nhật Thu hoạch',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context, false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: _inputDecoration('Ngày dự kiến',
                              prefixIcon: Icons.calendar_today,
                              suffixIcon: Icons.edit_calendar),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_expectedDate),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: _inputDecoration('Sản lượng',
                                  prefixIcon: Icons.scale_outlined),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Nhập SL' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: _inputDecoration('Đơn vị'),
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
                        value: _selectedStatus,
                        decoration: _inputDecoration('Trạng thái',
                            prefixIcon: Icons.assignment_turned_in_outlined),
                        items: _statuses.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedStatus = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        decoration:
                            _inputDecoration('Ghi chú', prefixIcon: Icons.notes)
                                .copyWith(alignLabelWithHint: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu thay đổi',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

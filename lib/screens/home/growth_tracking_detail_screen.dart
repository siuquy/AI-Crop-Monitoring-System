import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class GrowthTrackingDetailScreen extends StatefulWidget {
  final String farmId;
  final String plotId;
  final String bedId;
  final String seasonId;

  final String farmName;
  final String plotName;
  final String bedName;
  final String seasonName;

  const GrowthTrackingDetailScreen({
    super.key,
    required this.farmId,
    required this.plotId,
    required this.bedId,
    required this.seasonId,
    required this.farmName,
    required this.plotName,
    required this.bedName,
    required this.seasonName,
  });

  @override
  State<GrowthTrackingDetailScreen> createState() =>
      _GrowthTrackingDetailScreenState();
}

class _GrowthTrackingDetailScreenState
    extends State<GrowthTrackingDetailScreen> {
  bool _isLoading = true;

  String _fetchedStage = 'Giai đoạn sinh trưởng (Sinh dưỡng)';
  String _fetchedHealth = 'Bình thường';
  String _fetchedNote = 'Cây đang phát triển tốt, lá xanh đều.';
  DateTime _lastUpdated = DateTime.now().subtract(const Duration(days: 2));

  // Thông tin dùng để form cập nhật
  String _currentStage = 'Giai đoạn sinh trưởng (Sinh dưỡng)';
  String _healthStatus = 'Bình thường';
  final TextEditingController _noteController = TextEditingController();

  final List<String> _stages = [
    'Giai đoạn cây con (Nảy mầm)',
    'Giai đoạn sinh trưởng (Sinh dưỡng)',
    'Giai đoạn ra hoa',
    'Giai đoạn đậu quả / Kết hạt',
    'Giai đoạn thu hoạch',
  ];

  final List<String> _healthStatuses = [
    'Bình thường',
    'Cần chú ý',
    'Bị bệnh / Sâu hại',
    'Suy yếu',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    // Có thể gọi API tại đây để lấy thông tin gần nhất của Luống + Mùa vụ
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStage = _fetchedStage;
        _healthStatus = _fetchedHealth;
        _noteController.text = ''; // Để trống cho lần cập nhật mới
      });
    }
  }

  void _saveUpdate() async {
    // TODO: Gắn API Cập nhật Tracking Data tại đây
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cập nhật thông tin sinh trưởng thành công!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Chi tiết sinh trưởng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildCurrentStatusCard(),
                  const SizedBox(height: 20),
                  const Text(
                    'Cập nhật trạng thái',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  _buildUpdateForm(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Lưu cập nhật",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saveUpdate,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              const Icon(Icons.location_on, color: primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.farmName} > ${widget.plotName} > ${widget.bedName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(Icons.calendar_month, 'Mùa vụ:', widget.seasonName),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tình trạng hiện tại',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.spa_outlined, 'Giai đoạn:', _fetchedStage),
          const SizedBox(height: 12),
          _infoRow(
              Icons.health_and_safety_outlined, 'Sức khỏe:', _fetchedHealth,
              valueColor: _fetchedHealth == 'Bình thường'
                  ? Colors.green
                  : Colors.orange),
          const SizedBox(height: 12),
          _infoRow(Icons.note_alt_outlined, 'Ghi chú:',
              _fetchedNote.isEmpty ? 'Không có' : _fetchedNote),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, 'Cập nhật lần cuối:',
              DateFormat('dd/MM/yyyy HH:mm').format(_lastUpdated)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: valueColor ?? Colors.black87),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Giai đoạn hiện tại',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _currentStage,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _stages
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => _currentStage = val!),
          ),
          const SizedBox(height: 16),
          const Text('Tình trạng sức khỏe',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _healthStatus,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _healthStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => _healthStatus = val!),
          ),
          const SizedBox(height: 16),
          const Text('Ghi chú quan sát',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập nhận xét tình hình sinh trưởng...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

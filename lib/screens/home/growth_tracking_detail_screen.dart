import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/growth_tracking_service.dart';
import '../../models/growth_tracking.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class GrowthTrackingDetailScreen extends StatefulWidget {
  final String? farmId;
  final String? plotId;
  final String? bedId;
  final String? seasonId;

  final String? farmName;
  final String? plotName;
  final String? bedName;
  final String? seasonName;

  final GrowthTracking? tracking;

  const GrowthTrackingDetailScreen({
    super.key,
    this.farmId,
    this.plotId,
    this.bedId,
    this.seasonId,
    this.farmName,
    this.plotName,
    this.bedName,
    this.seasonName,
    this.tracking,
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

  String _currentStage = 'Giai đoạn sinh trưởng (Sinh dưỡng)';
  String _healthStatus = 'Bình thường';
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  List<String> _stages = [
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
    if (widget.tracking != null) {
      // Đổ dữ liệu có sẵn lên UI
      _fetchedStage = widget.tracking!.stageName;

      String health = widget.tracking!.healthStatus ?? 'Good';
      if (health == 'Warning')
        _fetchedHealth = 'Cần chú ý';
      else if (health == 'Bad')
        _fetchedHealth = 'Bị bệnh / Sâu hại';
      else
        _fetchedHealth = 'Bình thường';

      _fetchedNote = widget.tracking!.notes ?? 'Không có ghi chú';
      _lastUpdated = widget.tracking!.updatedAt ??
          widget.tracking!.createdAt ??
          DateTime.now();

      _currentStage = _fetchedStage;
      if (!_stages.contains(_currentStage)) {
        _stages.insert(0, _currentStage);
      }

      _healthStatus = _fetchedHealth;
      _heightController.text = widget.tracking!.actualHeight?.toString() ?? '';
      _noteController.text = widget.tracking!.notes ?? '';
      _isLoading = false;
    } else {
      _fetchDetail();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentStage = _stages[0]; // Mặc định ở Giai đoạn Nảy mầm khi tạo mới
        _healthStatus = _healthStatuses[0]; // Mặc định Bình thường
        _noteController.text = ''; // Để trống cho lần cập nhật mới
        _heightController.text = '';
      });
    }
  }

  void _saveUpdate() async {
    setState(() => _isLoading = true);

    try {
      final actualHeight = double.tryParse(_heightController.text) ?? 0.0;

      String apiHealthStatus = 'Good';
      if (_healthStatus == 'Cần chú ý') apiHealthStatus = 'Warning';
      if (_healthStatus == 'Bị bệnh / Sâu hại' || _healthStatus == 'Suy yếu')
        apiHealthStatus = 'Bad';

      GrowthTracking? newTracking;

      // Bổ sung thông báo để dễ theo dõi tiến trình
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.tracking != null
                  ? 'Đang cập nhật dữ liệu...'
                  : 'Đang tạo bản ghi mới...')),
        );
      }

      if (widget.tracking != null) {
        // Gọi Update (PUT)
        newTracking = await GrowthTrackingService.updateGrowthTracking(
          trackingId: widget.tracking!.trackingId,
          trackingStatus: 'In-Progress',
          healthStatus: apiHealthStatus,
          actualHeight: actualHeight,
          notes: _noteController.text.trim().isEmpty
              ? 'none'
              : _noteController.text.trim(),
        );
      } else {
        // Gọi Create (POST) cho nhánh chọn tạo mới từ đầu chưa có dữ liệu
        newTracking = await GrowthTrackingService.createGrowthTracking(
          harvestDetailId: '4260d675-632b-46d6-b19d-bb892e5e04f4', // MOCK ID
          stageId: '54196e39-715a-4005-aabc-9d80bca83555', // MOCK ID
          startDate: DateTime.now().toUtc(),
          healthStatus: apiHealthStatus,
          actualHeight: actualHeight,
          notes: _noteController.text.trim().isEmpty
              ? 'none'
              : _noteController.text.trim(),
        );
      }

      if (mounted) {
        if (newTracking != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cập nhật thông tin sinh trưởng thành công!'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context,
              true); // Trả về `true` để trang ListScreen nhận biết và tải lại
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thất bại.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  if (widget.tracking != null) ...[
                    _buildCurrentStatusCard(),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    widget.tracking != null
                        ? 'Cập nhật trạng thái'
                        : 'Khởi tạo theo dõi',
                    style: const TextStyle(
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
                      label: Text(
                        widget.tracking != null ? "Lưu cập nhật" : "Tạo mới",
                        style: const TextStyle(
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
                  widget.tracking != null
                      ? '${widget.tracking!.cropName} > ${widget.tracking!.bedName}'
                      : '${widget.farmName} > ${widget.plotName} > ${widget.bedName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          if (widget.tracking == null) ...[
            const Divider(height: 24),
            _infoRow(Icons.calendar_month, 'Mùa vụ:', widget.seasonName ?? ''),
          ] else ...[
            const Divider(height: 24),
            _infoRow(Icons.spa, 'Cây trồng:', widget.tracking!.cropName),
          ]
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
              DateFormat('dd/MM/yyyy HH:mm').format(_lastUpdated.toLocal())),
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
          const Text('Chiều cao cây thực tế (cm)',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'VD: 15.5',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ghi chú quan sát',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
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

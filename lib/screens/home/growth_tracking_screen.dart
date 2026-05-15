import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/season_service.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class GrowthTrackingScreen extends StatefulWidget {
  const GrowthTrackingScreen({super.key});

  @override
  State<GrowthTrackingScreen> createState() => _GrowthTrackingScreenState();
}

class _GrowthTrackingScreenState extends State<GrowthTrackingScreen> {
  String? selectedFarmId;
  String? selectedPlotId;
  String? selectedBedId;
  String? selectedSeasonId;

  List<Map<String, dynamic>> _farms = [];
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, Map<String, dynamic>> _bedMap = {};
  List<Map<String, dynamic>> _seasons = [];

  bool _isLoading = true;
  bool _isLoadingDetails = false;
  bool _hasDetails = false;

  // Dữ liệu mô phỏng lấy từ API cho luống/mùa vụ
  String _fetchedStage = 'Giai đoạn sinh trưởng (Sinh dưỡng)';
  String _fetchedHealth = 'Bình thường';
  String _fetchedNote = 'Cây đang phát triển tốt, lá xanh đều.';
  DateTime _lastUpdated = DateTime.now().subtract(const Duration(days: 2));

  // Biến phục vụ cập nhật trạng thái mới
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

  List<Map<String, dynamic>> get _filteredPlots {
    if (selectedFarmId == null) return [];
    return _plotMap.entries
        .where((e) => e.value['farmId'] == selectedFarmId)
        .map((e) => {'id': e.key, 'name': e.value['plotName']})
        .toList();
  }

  List<Map<String, dynamic>> get _filteredBeds {
    if (selectedPlotId == null) return [];
    return _bedMap.entries
        .where((e) => e.value['plotId'].toString() == selectedPlotId)
        .map((e) => {'id': e.key, 'name': e.value['bedName']})
        .toList();
  }

  List<Map<String, dynamic>> get _filteredSeasons {
    if (selectedFarmId == null) return [];
    return _seasons
        .where((s) => s['farmId'].toString() == selectedFarmId)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
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
      setState(() {
        final farmMap = results[0] as Map<String, String>;
        _farms =
            farmMap.entries.map((e) => {'id': e.key, 'name': e.value}).toList();
        _plotMap = results[1] as Map<String, Map<String, dynamic>>;
        _bedMap = results[2] as Map<String, Map<String, dynamic>>;

        final seasonMap = results[3] as Map<String, Map<String, dynamic>>;
        _seasons = seasonMap.entries.map((e) {
          final seasonName = e.value['seasonName']?.toString() ?? 'Không rõ';
          final farmId = e.value['farmId']?.toString();
          return {'id': e.key, 'name': seasonName, 'farmId': farmId};
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _onFarmChanged(String? val) {
    setState(() {
      selectedFarmId = val;
      selectedPlotId = null;
      selectedBedId = null;
      selectedSeasonId = null;
      _hasDetails = false;
    });
    _checkAndFetchDetails();
  }

  void _onPlotChanged(String? val) {
    setState(() {
      selectedPlotId = val;
      selectedBedId = null;
      _hasDetails = false;
    });
    _checkAndFetchDetails();
  }

  void _onBedChanged(String? val) {
    setState(() {
      selectedBedId = val;
      _hasDetails = false;
    });
    _checkAndFetchDetails();
  }

  void _onSeasonChanged(String? val) {
    setState(() {
      selectedSeasonId = val;
      _hasDetails = false;
    });
    _checkAndFetchDetails();
  }

  void _checkAndFetchDetails() async {
    if (selectedFarmId != null &&
        selectedPlotId != null &&
        selectedBedId != null &&
        selectedSeasonId != null) {
      setState(() {
        _isLoadingDetails = true;
        _hasDetails = false;
      });

      // Giả lập gọi API lấy dữ liệu chi tiết của luống thuộc mùa vụ này
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
          _hasDetails = true;
          _currentStage = _fetchedStage;
          _healthStatus = _fetchedHealth;
          _noteController.clear();
        });
      }
    }
  }

  void _saveUpdate() async {
    // TODO: Gắn API Cập nhật Tracking Data tại đây
    setState(() => _isLoadingDetails = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoadingDetails = false;
        _fetchedStage = _currentStage;
        _fetchedHealth = _healthStatus;
        if (_noteController.text.trim().isNotEmpty) {
          _fetchedNote = _noteController.text;
        }
        _lastUpdated = DateTime.now();
        _noteController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cập nhật thông tin sinh trưởng thành công!'),
            backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    final safeValue =
        items.any((e) => e['id'].toString() == value) ? value : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: primaryTeal.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade300),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          prefixIcon: Icon(icon,
              color: enabled ? primaryTeal : Colors.grey.shade400, size: 22),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: enabled
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: enabled
                ? BorderSide.none
                : BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: primaryTeal.withOpacity(0.5), width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        style: TextStyle(
            color: enabled ? Colors.black87 : Colors.grey.shade600,
            fontSize: 15,
            fontWeight: FontWeight.w600),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['id'].toString(),
            child:
                Text(item['name'].toString(), overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryTeal.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.analytics_rounded,
                    color: Colors.blue.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tình trạng hiện tại',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _infoRow(Icons.spa_rounded, 'Giai đoạn:', _fetchedStage),
          const SizedBox(height: 14),
          _infoRow(Icons.health_and_safety_rounded, 'Sức khỏe:', _fetchedHealth,
              valueColor: _fetchedHealth == 'Bình thường'
                  ? Colors.green.shade600
                  : Colors.orange.shade700),
          const SizedBox(height: 14),
          _infoRow(Icons.note_alt_rounded, 'Ghi chú:',
              _fetchedNote.isEmpty ? 'Không có' : _fetchedNote),
          const SizedBox(height: 14),
          _infoRow(Icons.access_time_rounded, 'Cập nhật:',
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
        Icon(icon, size: 18, color: Colors.teal.shade400),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModernDropdownField(
            label: 'Giai đoạn hiện tại',
            value: _currentStage,
            items: _stages,
            onChanged: (val) => setState(() => _currentStage = val!),
          ),
          const SizedBox(height: 16),
          _buildModernDropdownField(
            label: 'Tình trạng sức khỏe',
            value: _healthStatus,
            items: _healthStatuses,
            onChanged: (val) => setState(() => _healthStatus = val!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Ghi chú quan sát',
              alignLabelWithHint: true,
              hintText: 'Nhập nhận xét tình hình sinh trưởng...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                borderSide:
                    BorderSide(color: primaryTeal.withOpacity(0.5), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      icon:
          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide:
              BorderSide(color: primaryTeal.withOpacity(0.5), width: 1.5),
        ),
      ),
      style: const TextStyle(
          color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
      items:
          items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Theo dõi sinh trưởng',
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
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
                          child: const Icon(Icons.dashboard_customize_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Khu vực theo dõi",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Lọc luống và mùa vụ để cập nhật",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDropdown(
                    label: "Trang trại",
                    icon: Icons.apartment,
                    value: selectedFarmId,
                    items: _farms,
                    onChanged: _onFarmChanged,
                  ),
                  _buildDropdown(
                    label: "Vuông / Ruộng",
                    icon: Icons.grass,
                    value: selectedPlotId,
                    items: _filteredPlots,
                    onChanged: _onPlotChanged,
                    enabled: selectedFarmId != null,
                  ),
                  _buildDropdown(
                    label: "Luống",
                    icon: Icons.spa,
                    value: selectedBedId,
                    items: _filteredBeds,
                    onChanged: _onBedChanged,
                    enabled: selectedPlotId != null,
                  ),
                  _buildDropdown(
                    label: "Mùa vụ",
                    icon: Icons.calendar_month,
                    value: selectedSeasonId,
                    items: _filteredSeasons,
                    onChanged: _onSeasonChanged,
                    enabled: selectedFarmId != null,
                  ),
                  if (_isLoadingDetails)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(
                          child: CircularProgressIndicator(color: primaryTeal)),
                    )
                  else if (_hasDetails) ...[
                    const SizedBox(height: 24),
                    _buildCurrentStatusCard(),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.edit_document, color: primaryTeal, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Cập nhật trạng thái mới',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUpdateForm(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded, size: 22),
                        label: const Text(
                          "Lưu cập nhật",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: _saveUpdate,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

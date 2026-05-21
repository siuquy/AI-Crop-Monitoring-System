import 'package:flutter/material.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/season_service.dart';
import 'growth_tracking_list_screen.dart';

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
  bool _isChecking = false;

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

  void _onProceed() async {
    if (selectedFarmId == null ||
        selectedPlotId == null ||
        selectedBedId == null ||
        selectedSeasonId == null) return;

    final farmName =
        _farms.firstWhere((f) => f['id'] == selectedFarmId)['name'].toString();
    final plotName = _filteredPlots
        .firstWhere((p) => p['id'] == selectedPlotId)['name']
        .toString();
    final bedName = _filteredBeds
        .firstWhere((b) => b['id'] == selectedBedId)['name']
        .toString();
    final seasonName = _filteredSeasons
        .firstWhere((s) => s['id'] == selectedSeasonId)['name']
        .toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrowthTrackingListScreen(
          farmId: selectedFarmId!,
          plotId: selectedPlotId!,
          bedId: selectedBedId!,
          seasonId: selectedSeasonId!,
          farmName: farmName,
          plotName: plotName,
          bedName: bedName,
          seasonName: seasonName,
        ),
      ),
    );
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
      margin: const EdgeInsets.only(bottom: 16.0),
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

  @override
  Widget build(BuildContext context) {
    final bool canProceed = selectedFarmId != null &&
        selectedPlotId != null &&
        selectedBedId != null &&
        selectedSeasonId != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Chọn khu vực',
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
                          child: const Icon(Icons.location_on_rounded,
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
                                "Chọn đầy đủ thông tin để tiếp tục",
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
                    onChanged: (val) => setState(() {
                      selectedFarmId = val;
                      selectedPlotId = null;
                      selectedBedId = null;
                      selectedSeasonId = null;
                    }),
                  ),
                  _buildDropdown(
                    label: "Vuông / Ruộng",
                    icon: Icons.grass,
                    value: selectedPlotId,
                    items: _filteredPlots,
                    onChanged: (val) => setState(() {
                      selectedPlotId = val;
                      selectedBedId = null;
                    }),
                    enabled: selectedFarmId != null,
                  ),
                  _buildDropdown(
                    label: "Luống",
                    icon: Icons.spa,
                    value: selectedBedId,
                    items: _filteredBeds,
                    onChanged: (val) => setState(() => selectedBedId = val),
                    enabled: selectedPlotId != null,
                  ),
                  _buildDropdown(
                    label: "Mùa vụ",
                    icon: Icons.calendar_month,
                    value: selectedSeasonId,
                    items: _filteredSeasons,
                    onChanged: (val) => setState(() => selectedSeasonId = val),
                    enabled: selectedFarmId != null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: canProceed ? _onProceed : null,
                      icon: const Icon(Icons.list_alt_rounded, size: 22),
                      label: const Text(
                        "Xem chi tiết",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

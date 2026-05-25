import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/growth_tracking_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/season_service.dart';
import '../../models/growth_tracking.dart';
import 'growth_tracking_detail_screen.dart';

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

  GrowthTracking? _latestTracking;
  bool _isLoadingTracking = false;
  bool _hasSearched = false;

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

    final bedName = _filteredBeds
        .firstWhere((b) => b['id'] == selectedBedId)['name']
        .toString();

    _fetchLatestTracking(bedName);
  }

  Future<void> _fetchLatestTracking(String selectedBedName) async {
    setState(() {
      _isLoadingTracking = true;
      _latestTracking = null;
      _hasSearched = true;
    });

    try {
      final trackings = await GrowthTrackingService.getGrowthTrackings();

      final filteredTrackings =
          trackings.where((t) => t.bedName == selectedBedName).toList();

      filteredTrackings.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime.now();
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      setState(() {
        _latestTracking =
            filteredTrackings.isNotEmpty ? filteredTrackings.first : null;
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu sinh trưởng: $e');
    } finally {
      setState(() {
        _isLoadingTracking = false;
      });
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
              color: enabled ? primaryTeal : Colors.grey.shade400, size: 20),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            fontSize: 14,
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
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: "Trang trại",
                          icon: Icons.apartment,
                          value: selectedFarmId,
                          items: _farms,
                          onChanged: (val) => setState(() {
                            selectedFarmId = val;
                            selectedPlotId = null;
                            selectedBedId = null;
                            selectedSeasonId = null;
                            _hasSearched = false;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: "Khu vực",
                          icon: Icons.grass,
                          value: selectedPlotId,
                          items: _filteredPlots,
                          onChanged: (val) => setState(() {
                            selectedPlotId = val;
                            selectedBedId = null;
                            _hasSearched = false;
                          }),
                          enabled: selectedFarmId != null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: "Luống",
                          icon: Icons.spa,
                          value: selectedBedId,
                          items: _filteredBeds,
                          onChanged: (val) => setState(() {
                            selectedBedId = val;
                            _hasSearched = false;
                          }),
                          enabled: selectedPlotId != null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: "Mùa vụ",
                          icon: Icons.calendar_month,
                          value: selectedSeasonId,
                          items: _filteredSeasons,
                          onChanged: (val) => setState(() {
                            selectedSeasonId = val;
                            _hasSearched = false;
                          }),
                          enabled: selectedFarmId != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: canProceed ? _onProceed : null,
                      icon: const Icon(Icons.search_rounded, size: 22),
                      label: const Text(
                        "Tra cứu sinh trưởng",
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
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  if (_hasSearched) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildLatestTrackingCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          "Thêm ghi chép mới",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryTeal,
                          side: const BorderSide(color: primaryTeal, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedFarmId == null ||
                              selectedPlotId == null ||
                              selectedBedId == null ||
                              selectedSeasonId == null) return;

                          final farmName = _farms
                              .firstWhere(
                                  (f) => f['id'] == selectedFarmId)['name']
                              .toString();
                          final plotName = _filteredPlots
                              .firstWhere(
                                  (p) => p['id'] == selectedPlotId)['name']
                              .toString();
                          final bedName = _filteredBeds
                              .firstWhere(
                                  (b) => b['id'] == selectedBedId)['name']
                              .toString();
                          final seasonName = _filteredSeasons
                              .firstWhere(
                                  (s) => s['id'] == selectedSeasonId)['name']
                              .toString();

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GrowthTrackingDetailScreen(
                                farmId: selectedFarmId!,
                                plotId: selectedPlotId!,
                                bedId: selectedBedId!,
                                seasonId: selectedSeasonId!,
                                farmName: farmName,
                                plotName: plotName,
                                bedName: bedName,
                                seasonName: seasonName,
                                tracking: null,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchLatestTracking(bedName);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildLatestTrackingCard() {
    if (_isLoadingTracking) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: primaryTeal)),
      );
    }

    if (_latestTracking == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Chưa có dữ liệu sinh trưởng nào cho luống này.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final tracking = _latestTracking!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    GrowthTrackingDetailScreen(tracking: tracking),
              ),
            );
            if (result == true) {
              _fetchLatestTracking(tracking.bedName);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.spa_rounded,
                          color: primaryTeal, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tracking.cropName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tracking.bedName,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getHealthColor(tracking.healthStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getHealthText(tracking.healthStatus),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(tracking.healthStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Giai đoạn', tracking.stageName),
                    _buildInfoColumn(
                        'Cập nhật',
                        tracking.updatedAt != null
                            ? DateFormat('dd/MM HH:mm')
                                .format(tracking.updatedAt!.toLocal())
                            : '--/--'),
                    _buildInfoColumn(
                        'Chiều cao', '${tracking.actualHeight ?? 0} cm'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getHealthColor(String? status) {
    if (status == 'Good') return Colors.green.shade600;
    if (status == 'Warning') return Colors.orange.shade600;
    if (status == 'Bad') return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  String _getHealthText(String? status) {
    if (status == 'Good') return 'Tốt';
    if (status == 'Warning') return 'Chú ý';
    if (status == 'Bad') return 'Xấu';
    return 'Không rõ';
  }

  Widget _buildInfoColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

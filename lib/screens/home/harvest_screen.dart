import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/harvest_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import '../../core/service/season_service.dart';
import 'create_harvest_screen.dart';
import 'update_harvest_dialog.dart';
import 'update_harvest_detail_dialog.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  List<Map<String, dynamic>> _harvests = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FarmService.getFarmMap(),
        PlotService.getPlotMap(),
        SeasonService.getSeasonMap(),
      ]);

      if (mounted) {
        setState(() {
          _farmMap = results[0] as Map<String, String>;
          _plotMap = results[1] as Map<String, Map<String, dynamic>>;
          _seasonMap = results[2] as Map<String, Map<String, dynamic>>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu dropdown: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _fetchHarvests() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final harvests = await HarvestService.getHarvests(
        farmId: _selectedFarmId,
        plotId: _selectedPlotId,
        seasonId: _selectedSeasonId,
      );
      if (mounted) {
        setState(() {
          _harvests = harvests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
        title: const Text('Danh sách Thu hoạch',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchPanel(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          debugPrint(
              '[HarvestScreen] Đang chuyển sang màn hình Tạo Thu Hoạch...');
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateHarvestScreen(
                initialPlotId: _selectedPlotId,
                initialSeasonId: _selectedSeasonId,
              ),
            ),
          );
          if (result == true && _hasSearched) {
            _fetchHarvests(); // Tải lại danh sách nếu thêm mới thành công
          }
        },
        backgroundColor: primaryTeal, // Đã mở khóa tính năng
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo thu hoạch',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchPanel() {
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

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          )),
      child: Column(
        children: [
          if (_isLoadingData)
            const Center(child: CircularProgressIndicator(color: primaryTeal))
          else ...[
            DropdownButtonFormField<String>(
              value: _farmMap.containsKey(_selectedFarmId)
                  ? _selectedFarmId
                  : null,
              decoration:
                  _dropdownDecoration('Trang trại', Icons.agriculture_outlined),
              items: _farmMap.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedFarmId = val;
                  _selectedPlotId = null;
                  _selectedSeasonId = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPlotId != null &&
                            availablePlots.any((p) => p.key == _selectedPlotId)
                        ? _selectedPlotId
                        : null,
                    decoration: _dropdownDecoration(
                        'Khu vực', Icons.location_on_outlined),
                    items: availablePlots
                        .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                                e.value['plotName']?.toString() ??
                                    'Khu vực ${e.key}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    isExpanded: true,
                    onChanged: (val) => setState(() => _selectedPlotId = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeasonId != null &&
                            availableSeasons
                                .any((s) => s.key == _selectedSeasonId)
                        ? _selectedSeasonId
                        : null,
                    decoration: _dropdownDecoration(
                        'Mùa vụ', Icons.calendar_month_outlined),
                    items: availableSeasons
                        .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(
                                e.value['seasonName']?.toString() ??
                                    'Mùa vụ ${e.key}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    isExpanded: true,
                    onChanged: (val) => setState(() => _selectedSeasonId = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchHarvests,
                icon: const Icon(Icons.search),
                label: const Text('Tìm kiếm Thu hoạch',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryTeal, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5)),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryTeal));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchHarvests,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 64, color: primaryTeal),
            ),
            const SizedBox(height: 24),
            const Text('Tìm kiếm thu hoạch',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Chọn Trang trại, Khu vực và Mùa vụ ở trên.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    if (_harvests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.eco_outlined, size: 64, color: primaryTeal),
            ),
            const SizedBox(height: 24),
            const Text('Chưa có dữ liệu',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Nhấn "Tạo thu hoạch" để thêm mới.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHarvests,
      color: primaryTeal,
      child: ListView.separated(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: _harvests.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeaderCard();
          final harvest = _harvests[index - 1];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final id = harvest['harvestId']?.toString();

                  if (id != null) {
                    _showHarvestDetailDialog(context, id);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Dữ liệu không hợp lệ, không tìm thấy ID thu hoạch.')),
                    );
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
                            child: const Icon(Icons.eco_rounded,
                                color: primaryTeal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  harvest['cropName']?.toString() ??
                                      'Không rõ cây trồng',
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
                                        harvest['plotName']?.toString() ??
                                            'Không rõ khu vực',
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
                          const SizedBox(width: 8),
                          _buildStatusBadge(harvest['status']?.toString()),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded,
                                color: primaryTeal, size: 28),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showUpdateDialog(harvest),
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
                          _buildInfoColumn('SL (dự kiến)', Icons.scale_outlined,
                              '${harvest['expectedQuantity'] ?? 0} ${harvest['unit'] ?? 'kg'}'),
                          _buildInfoColumn(
                              'Ngày thu hoạch',
                              Icons.calendar_today_outlined,
                              harvest['expectedDate'] != null
                                  ? DateFormat('dd/MM/yyyy').format(
                                      DateTime.tryParse(harvest['expectedDate']
                                                  .toString())
                                              ?.toLocal() ??
                                          DateTime.now())
                                  : '--/--/----'),
                          _buildInfoColumn(
                              'Số lượng luống',
                              Icons.format_list_numbered_rounded,
                              '${harvest['harvestedBedsCount'] ?? 0}/${harvest['detailsCount'] ?? 0} luống'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng quan Thu hoạch',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã ghi nhận ${_harvests.length} đợt thu hoạch trong hệ thống.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final isCompleted = status == 'completed' || status == 'Hoàn thành';
    final bgColor = isCompleted ? Colors.green.shade50 : Colors.orange.shade50;
    final textColor =
        isCompleted ? Colors.green.shade700 : Colors.orange.shade800;
    final label = isCompleted ? 'Hoàn thành' : 'Đang chờ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, IconData icon, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showHarvestDetailDialog(BuildContext context, String harvestId) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: HarvestService.getHarvestDetailsByHarvestId(harvestId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: primaryTeal),
                          SizedBox(height: 16),
                          Text('Đang tải danh sách luống...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          const Text('Không thể tải chi tiết thu hoạch.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryTeal),
                            child: const Text('Đóng',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  final details = snapshot.data!;

                  return Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chi tiết luống (${details.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        if (details.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                  'Chưa có danh sách luống cho đợt này.',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: details.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final detail = details[index];
                                final isHarvested =
                                    detail['isHarvested'] == true;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    detail['bedName']?.toString() ?? 'Luống',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                          'Sản lượng: ${detail['cropQuantity'] ?? 0} kg'),
                                      Text(
                                          'Từ: ${_formatDateStr(detail['startDate']?.toString())} - Đến: ${_formatDateStr(detail['endDate']?.toString())}'),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isHarvested
                                                ? Icons.check_circle
                                                : Icons.pending_actions,
                                            size: 16,
                                            color: isHarvested
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isHarvested
                                                ? 'Đã thu hoạch'
                                                : 'Đang chờ',
                                            style: TextStyle(
                                              color: isHarvested
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: OutlinedButton(
                                    onPressed: () async {
                                      final result = await showDialog(
                                        context: context,
                                        builder: (context) =>
                                            UpdateHarvestDetailDialog(
                                                detail: detail),
                                      );
                                      if (result == true) {
                                        setStateDialog(
                                            () {}); // Reload FutureBuilder
                                        _fetchHarvests(); // Update outside progress
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryTeal,
                                      side:
                                          const BorderSide(color: primaryTeal),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    child: const Text('Cập nhật'),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatDateStr(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return dateStr;
    }
  }

  void _showUpdateDialog(Map<String, dynamic> harvest) async {
    final id = harvest['harvestId']?.toString();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy ID đợt thu hoạch')),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => UpdateHarvestDialog(
        harvestId: id,
        initialDate: harvest['expectedDate'] != null
            ? DateTime.tryParse(harvest['expectedDate'].toString())
            : null,
        initialQuantity:
            double.tryParse(harvest['expectedQuantity']?.toString() ?? '0') ??
                0.0,
        initialUnit: harvest['unit']?.toString() ?? 'kg',
        initialStatus: harvest['status']?.toString() ?? 'pending',
        initialNotes: harvest['notes']?.toString() ?? '',
      ),
    );

    if (result == true) {
      _fetchHarvests(); // Reload list if updated successfully
    }
  }
}

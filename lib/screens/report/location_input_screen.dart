import 'package:flutter/material.dart';
import '../../core/service/bed_service.dart';
import '../../core/service/farm_service.dart';
import '../../core/service/plot_service.dart';
import 'camera_scan_screen.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

class LocationInputScreen extends StatefulWidget {
  const LocationInputScreen({super.key});

  @override
  State<LocationInputScreen> createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  String? selectedFarmId;
  String? selectedFarmName;

  String? selectedPlotId;
  String? selectedPlotName;

  String? selectedBedId;
  String? selectedBedName;

  List<Map<String, dynamic>> _farms = [];
  Map<String, Map<String, dynamic>> _plotMap = {};
  Map<String, Map<String, dynamic>> _bedMap = {};

  bool _isLoading = true;

  List<Map<String, dynamic>> get _filteredPlots {
    if (selectedFarmId == null) return [];
    return _plotMap.entries
        .where((e) => e.value['farmId'] == selectedFarmId)
        .map((e) => {'plotId': e.key, 'plotName': e.value['plotName']})
        .toList();
  }

  List<Map<String, dynamic>> get _filteredBeds {
    if (selectedPlotId == null) return [];
    return _bedMap.entries
        .where((e) => e.value['plotId'].toString() == selectedPlotId)
        .map((e) => {'bedId': e.key, 'bedName': e.value['bedName']})
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
      ]);
      setState(() {
        final farmMap = results[0] as Map<String, String>;
        _farms = farmMap.entries
            .map((e) => {'farmId': e.key, 'farmName': e.value})
            .toList();
        _plotMap = results[1] as Map<String, Map<String, dynamic>>;
        _bedMap = results[2] as Map<String, Map<String, dynamic>>;
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

  Future<Map<String, String>?> _showPicker({
    required String title,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String nameKey,
    String? currentId,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final id = item[idKey].toString();
                  final name = item[nameKey].toString();
                  final isSelected = id == currentId;
                  return ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? primaryTeal : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: primaryTeal)
                        : null,
                    onTap: () =>
                        Navigator.pop(context, {'id': id, 'name': name}),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _pickFarm() async {
    if (_farms.isEmpty) return;
    final result = await _showPicker(
      title: 'Chọn trang trại',
      items: _farms,
      idKey: 'farmId',
      nameKey: 'farmName',
      currentId: selectedFarmId,
    );
    if (result != null) {
      setState(() {
        selectedFarmId = result['id'];
        selectedFarmName = result['name'];
        selectedPlotId = null;
        selectedPlotName = null;
        selectedBedId = null;
        selectedBedName = null;
      });
    }
  }

  void _pickPlot() async {
    if (_filteredPlots.isEmpty) return;
    final result = await _showPicker(
      title: 'Chọn ruộng',
      items: _filteredPlots,
      idKey: 'plotId',
      nameKey: 'plotName',
      currentId: selectedPlotId,
    );
    if (result != null) {
      setState(() {
        selectedPlotId = result['id'];
        selectedPlotName = result['name'];
        selectedBedId = null;
        selectedBedName = null;
      });
    }
  }

  void _pickBed() async {
    if (_filteredBeds.isEmpty) return;
    final result = await _showPicker(
      title: 'Chọn luống canh tác',
      items: _filteredBeds,
      idKey: 'bedId',
      nameKey: 'bedName',
      currentId: selectedBedId,
    );
    if (result != null) {
      setState(() {
        selectedBedId = result['id'];
        selectedBedName = result['name'];
      });
    }
  }

  void startScan() {
    if (selectedFarmId == null ||
        selectedPlotId == null ||
        selectedBedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn đầy đủ vị trí")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the selected location IDs to the camera screen.
        builder: (_) => CameraScanScreen(
          farmId: selectedFarmId!,
          plotId: selectedPlotId!,
          bedId: selectedBedId!,
        ),
      ),
    );
  }

  Widget _locationCard({
    required String title,
    required String hint,
    required IconData icon,
    required String? selectedName,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final bool hasValue = selectedName != null;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryTeal.withOpacity(enabled ? 0.15 : 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled ? primaryTeal : primaryTeal.withOpacity(0.4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: enabled ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? selectedName! : hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasValue ? primaryTeal : Colors.grey,
                      fontWeight:
                          hasValue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? Colors.black45 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Nhập vị trí phát hiện",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Chọn vị trí ruộng cần quét",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Vui lòng chọn thông tin chi tiết về vị trí canh tác",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _locationCard(
                    title: "Trang trại",
                    hint: "Chọn trang trại",
                    icon: Icons.apartment,
                    selectedName: selectedFarmName,
                    onTap: _pickFarm,
                  ),
                  _locationCard(
                    title: "Ruộng",
                    hint: "Chọn ruộng",
                    icon: Icons.grass,
                    selectedName: selectedPlotName,
                    onTap: _pickPlot,
                    enabled: selectedFarmId != null,
                  ),
                  _locationCard(
                    title: "Luống",
                    hint: "Chọn luống canh tác",
                    icon: Icons.spa,
                    selectedName: selectedBedName,
                    onTap: _pickBed,
                    enabled: selectedPlotId != null,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        "Bắt đầu quét",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: startScan,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

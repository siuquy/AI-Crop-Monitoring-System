import 'package:flutter/material.dart';
import 'camera_scan_screen.dart';

const Color primaryTeal = Color(0xFF1FCFC5);

class LocationInputScreen extends StatefulWidget {
  const LocationInputScreen({super.key});

  @override
  State<LocationInputScreen> createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  String? farm;
  String? field;
  String? area;
  String? row;

  final farms = ["Trang trại A", "Trang trại B"];
  final fields = ["Ruộng 1", "Ruộng 2", "Ruộng 3"];
  final areas = ["Khu 1", "Khu 2"];
  final rows = ["Luống 10", "Luống 11", "Luống 12"];

  void startScan() {
    if (farm == null || field == null || area == null || row == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn đầy đủ vị trí")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScanScreen(
          farm: farm!,
          field: field!,
          area: area!,
          row: row!,
        ),
      ),
    );
  }

  Widget locationCard({
    required String title,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
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
              color: primaryTeal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryTeal),
          ),
          const SizedBox(width: 12),

          /// TEXT + DROPDOWN
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                isExpanded: true,
                items: items.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chọn vị trí ruộng cần quét",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Vui lòng chọn thông tin chi tiết về vị trí canh tác",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            locationCard(
              title: "Trang trại",
              hint: "Chọn trang trại",
              icon: Icons.apartment,
              value: farm,
              items: farms,
              onChanged: (v) => setState(() => farm = v),
            ),

            locationCard(
              title: "Ruộng",
              hint: "Chọn ruộng",
              icon: Icons.grass,
              value: field,
              items: fields,
              onChanged: (v) => setState(() => field = v),
            ),

            locationCard(
              title: "Khu",
              hint: "Chọn khu vực",
              icon: Icons.layers,
              value: area,
              items: areas,
              onChanged: (v) => setState(() => area = v),
            ),

            locationCard(
              title: "Luống",
              hint: "Chọn luống canh tác",
              icon: Icons.spa,
              value: row,
              items: rows,
              onChanged: (v) => setState(() => row = v),
            ),

            const Spacer(),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  "Bắt đầu quét",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: startScan,
              ),
            )
          ],
        ),
      ),
    );
  }
}

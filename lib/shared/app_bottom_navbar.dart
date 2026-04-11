import 'package:acmms/screens/profile/settings_screen.dart';
import 'package:acmms/screens/report/location_input_screen.dart';
import 'package:acmms/screens/report/report_screen.dart';
import 'package:acmms/screens/report/scan_history_screen.dart';
import 'package:flutter/material.dart';
import 'bottom_tab.dart';
import '../screens/home/home_screen.dart';
import '../screens/task/task_list_screen.dart';

const Color primaryTeal = Color(0xFF4CAF50); 

class AppBottomNav extends StatelessWidget {
  final BottomTab currentTab;

  const AppBottomNav({
    super.key,
    required this.currentTab,
  });

  void _navigate(BuildContext context, BottomTab tab) {
    if (tab == currentTab) return;

    Widget page;

    switch (tab) {
      case BottomTab.home:
        page = const HomeScreen();
        break;
      case BottomTab.task:
        page = const TaskListScreen();
        break;
      case BottomTab.scan:
        page = const LocationInputScreen();
        break;
      case BottomTab.report:
        page = const ReportScreen();
        break;
      case BottomTab.setting:
        page = const SettingsScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(
                context,
                icon: Icons.home,
                label: 'Trang chủ',
                tab: BottomTab.home,
              ),
              _item(
                context,
                icon: Icons.task,
                label: 'Công việc',
                tab: BottomTab.task,
              ),
              _centerItem(context),
              _item(
                context,
                icon: Icons.bar_chart,
                label: 'Báo cáo',
                tab: BottomTab.report,
              ),
              _item(
                context,
                icon: Icons.settings,
                label: 'Cài đặt',
                tab: BottomTab.setting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required BottomTab tab,
  }) {
    final active = tab == currentTab;
    final color = active ? primaryTeal : Colors.grey;

    return InkWell(
      onTap: () => _navigate(context, tab),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Tùy chọn nhận diện',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner, color: Colors.teal),
                ),
                title: const Text('Quét bệnh mới',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chọn vị trí và chụp ảnh để AI phân tích'),
                onTap: () {
                  Navigator.pop(ctx); // Đóng pop-up
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LocationInputScreen()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: Colors.blue),
                ),
                title: const Text('Xem lịch sử',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Xem lại danh sách các ảnh đã quét'),
                onTap: () {
                  Navigator.pop(ctx); // Đóng pop-up
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScanHistoryScreen()));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _centerItem(BuildContext context) {
    return InkWell(
      onTap: () {
        _showCameraOptions(context);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: primaryTeal,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

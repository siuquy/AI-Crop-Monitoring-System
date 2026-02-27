import 'package:acmms/screens/report/report_view_screen.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/material.dart';

enum ReportStatus {
  approved,
  pending,
  needMoreInfo,
}

class ReportModel {
  final String title;
  final String disease;
  final String time;
  final String imageAsset;
  final ReportStatus status;

  ReportModel({
    required this.title,
    required this.disease,
    required this.time,
    required this.imageAsset,
    required this.status,
  });
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> tabs = [
    'Tất cả',
    'Chờ duyệt',
    'Đã duyệt',
    'Yêu cầu bổ sung',
  ];

  final List<ReportModel> reports = [
    ReportModel(
      title: 'Ruộng Cà chua - Khu B - Luống 2',
      disease: 'Sâu bệnh: Rầy nâu',
      time: '08:30 - 21/10/2023',
      imageAsset: 'assets/task/sick.jpg',
      status: ReportStatus.approved,
    ),
    ReportModel(
      title: 'Vườn Cà chua - Khu A - Hàng 4',
      disease: 'Thiếu dinh dưỡng: Vàng lá',
      time: '16:45 - 20/10/2023',
      imageAsset: 'assets/task/sick.jpg',
      status: ReportStatus.pending,
    ),
    ReportModel(
      title: 'Ruộng Cà chua - Khu C',
      disease: 'Không xác định: Cắn ăn gốc',
      time: '14:20 - 19/10/2023',
      imageAsset: 'assets/task/sick.jpg',
      status: ReportStatus.needMoreInfo,
    ),
  ];

  @override
  void initState() {
    _tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  List<ReportModel> getFilteredReports() {
    switch (_tabController.index) {
      case 1:
        return reports.where((r) => r.status == ReportStatus.pending).toList();
      case 2:
        return reports.where((r) => r.status == ReportStatus.approved).toList();
      case 3:
        return reports
            .where((r) => r.status == ReportStatus.needMoreInfo)
            .toList();
      default:
        return reports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = getFilteredReports();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Danh sách Báo cáo AI',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelColor: primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Tất cả"),
            Tab(text: "Chờ duyệt"),
            Tab(text: "Đã duyệt"),
            Tab(text: "Bổ sung"),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredReports.length,
        itemBuilder: (context, index) {
          final report = filteredReports[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportViewDetailScreen(
                    imagePath: report.imageAsset,
                    title: report.title,
                    diseaseName: report.disease,
                    level: _getLevelFromStatus(report.status),
                    date: report.time,
                    status: report.status,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      report.imageAsset,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.disease,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(report.status),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(
        currentTab: BottomTab.report,
      ),
    );
  }

  String _getLevelFromStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.approved:
        return "Nhẹ";
      case ReportStatus.pending:
        return "Trung bình";
      case ReportStatus.needMoreInfo:
        return "Nghiêm trọng";
    }
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    String text;

    switch (status) {
      case ReportStatus.approved:
        color = Colors.teal;
        text = 'Đã duyệt';
        break;
      case ReportStatus.pending:
        color = Colors.orange;
        text = 'Chờ duyệt';
        break;
      case ReportStatus.needMoreInfo:
        color = Colors.red;
        text = 'Yêu cầu bổ sung';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

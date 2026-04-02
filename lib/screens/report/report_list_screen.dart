import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service/report_service.dart';
import '../../models/report.dart';
import '../../models/report_status.dart';
import 'report_update_screen.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ReportService.getReports();
  }

  void _navigateToUpdateScreen(Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportUpdateScreen(
          title: report.title,
          diseaseName: report.diseaseName,
          imagePath: report.imageUrl, // Cần xử lý đường dẫn này
          ownerComment: report.ownerComment ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử báo cáo'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3F6F9),
      body: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Chưa có báo cáo nào.'),
            );
          }

          final reports = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ReportListItem(
                report: report,
                onTap: () {
                  if (report.status == ReportStatus.needsUpdate) {
                    _navigateToUpdateScreen(report);
                  } else {
                    // TODO: Điều hướng đến màn hình chi tiết báo cáo (read-only)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Xem chi tiết báo cáo: ${report.title}'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ReportListItem({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusTag(status: report.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Bệnh: ${report.diseaseName}',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final ReportStatus status;

  const _StatusTag({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

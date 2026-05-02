import 'package:acmms/models/report.dart';
import 'package:acmms/models/report_status.dart';
import 'package:acmms/screens/report/report_detail_screen.dart';
import 'package:acmms/screens/report/report_update_screen.dart';
import 'package:acmms/shared/app_bottom_navbar.dart';
import 'package:acmms/shared/bottom_tab.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service/report_service.dart';
import '../../screens/task/api_config.dart';

const Color primaryTeal = Color(0xFF4CAF50); // Xanh lá tươi
const Color darkTeal = Color(0xFF388E3C); // Xanh lá đậm
const Color bgColor = Color(0xFFF0F8F1); // Nền sáng ám xanh

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Future<List<Report>> _reportsFuture;
  List<Report> _allReports = [];
  DateTime? _selectedDate; // Thêm biến lưu ngày lọc
  ReportStatus? _currentFilter; // Thêm biến lưu trạng thái lọc

  @override
  void initState() {
    _loadReports();
    super.initState();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = ReportService.getReports();
    });
  }

  void _navigateToUpdate(Report report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportUpdateScreen(
          reportId: report.id,
          title: report.title,
          diseaseName: report.diseaseName ?? '',
          imagePath: report.imageUrl ?? '',
          ownerComment: report.ownerComment ?? '',
        ),
      ),
    );
    if (result == true) {
      _loadReports();
    }
  }

  List<Report> getFilteredReports() {
    List<Report> filtered = _allReports;

    // 1. Lọc theo trạng thái (ChoiceChip)
    if (_currentFilter != null) {
      filtered = filtered.where((r) => r.status == _currentFilter).toList();
    }

    // 2. Lọc theo ngày đã chọn
    if (_selectedDate != null) {
      filtered = filtered.where((r) {
        return r.createdAt.year == _selectedDate!.year &&
            r.createdAt.month == _selectedDate!.month &&
            r.createdAt.day == _selectedDate!.day;
      }).toList();
    }

    return filtered;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now()
          .add(const Duration(days: 365)), // Cho phép chọn đến năm sau
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Lịch sử Báo cáo',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined,
                color: primaryTeal, size: 28),
            onPressed: _pickDate,
            tooltip: 'Lọc theo ngày',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có báo cáo nào.'));
          }

          _allReports = snapshot.data!;
          final filteredReports = getFilteredReports();

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Không có báo cáo trong mục này',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadReports(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];

                            final String finalImageUrl = report.imageUrl != null
                                ? (report.imageUrl!.startsWith('http') ||
                                        report.imageUrl!.startsWith('assets/')
                                    ? report.imageUrl!
                                    : '${ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '')}/${report.imageUrl!.replaceAll(RegExp(r'^/'), '')}')
                                : '';

                            return GestureDetector(
                              onTap: () {
                                if (report.status == ReportStatus.needsUpdate) {
                                  _navigateToUpdate(report);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReportDetailScreen(report: report),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: finalImageUrl.isNotEmpty
                                          ? (finalImageUrl.startsWith('assets/')
                                              ? Image.asset(
                                                  finalImageUrl,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey),
                                                  ),
                                                )
                                              : Image.network(
                                                  finalImageUrl,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey.shade100,
                                                    child: const Icon(
                                                        Icons
                                                            .image_not_supported,
                                                        color: Colors.grey),
                                                  ),
                                                ))
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade100,
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  report.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildStatusBadge(report.status),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            report.description ??
                                                'Không có mô tả',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('dd/MM/yyyy HH:mm')
                                                    .format(report.createdAt
                                                        .toLocal()),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(
        currentTab: BottomTab.report,
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: status.color,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final availableStatuses = ReportStatus.values.where((status) {
      if (_allReports.isEmpty) return true;
      return _allReports.any((r) => r.status == status);
    }).toList();

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildFilterPill(null, 'Tất cả', primaryTeal),
          ...availableStatuses.map((status) =>
              _buildFilterPill(status, status.displayName, status.color)),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
      ReportStatus? status, String label, Color themeColor) {
    final isSelected = _currentFilter == status;

    String displayLabel = label;
    if (_allReports.isNotEmpty) {
      final count = status == null
          ? _allReports.length
          : _allReports.where((r) => r.status == status).length;
      displayLabel = '$label ($count)';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = status;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? themeColor.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSelected ? themeColor.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(status?.icon ?? Icons.dashboard_customize_rounded,
                  size: 16, color: themeColor),
              const SizedBox(width: 6),
            ],
            Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? themeColor : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/service/report_service.dart';
import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../screens/task/api_config.dart';
import 'report_detail_screen.dart';
import 'report_update_screen.dart';

const Color primaryTeal = Color(0xFF4CAF50);

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final List<Report> _reports = [];
  List<Report> _allReports = []; // Thêm biến lưu toàn bộ danh sách nội bộ
  ReportStatus? _currentFilter; // Biến lưu trạng thái lọc hiện tại
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 10; // Số lượng báo cáo tải mỗi lần
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReports(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Tải thêm khi người dùng cuộn gần đến cuối danh sách
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading) {
      _fetchReports();
    }
  }

  void _applyFilter(ReportStatus? filter) {
    if (_currentFilter == filter) return;

    // Tự động cuộn lên đầu danh sách mượt mà khi đổi bộ lọc
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    setState(() {
      _currentFilter = filter;
      _page = 1;
      _reports.clear();

      if (_allReports.isNotEmpty) {
        final filteredReports = filter == null
            ? _allReports
            : _allReports.where((r) => r.status == filter).toList();

        _reports.addAll(filteredReports.take(_limit));
        _hasMore = filteredReports.length > _limit;
        _page = _hasMore ? 2 : 1;
      } else {
        _hasMore = true;
      }
    });

    // Chỉ gọi API lại nếu danh sách gốc trống và không bị kẹt trạng thái loading
    if (_allReports.isEmpty && !_isLoading) {
      _fetchReports();
    }
  }

  Future<void> _fetchReports({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) _error = null;
    });

    if (isRefresh) {
      _page = 1;
      _hasMore = true;
      _reports.clear();
      _allReports.clear();
    }

    try {
      // Lấy toàn bộ báo cáo 1 lần nếu bộ đệm trống (Backend chưa hỗ trợ phân trang)
      if (_allReports.isEmpty) {
        _allReports = await ReportService.getReports();
      }

      // Áp dụng bộ lọc trạng thái
      final filteredReports = _currentFilter == null
          ? _allReports
          : _allReports.where((r) => r.status == _currentFilter).toList();

      // Phân trang nội bộ để tải từ từ các file đính kèm
      final startIndex = (_page - 1) * _limit;
      final newReports = filteredReports.skip(startIndex).take(_limit).toList();

      if (newReports.length < _limit ||
          startIndex + newReports.length >= filteredReports.length) {
        _hasMore = false;
      }

      setState(() {
        _reports.addAll(newReports);
        _hasMore = startIndex + newReports.length < filteredReports.length;
        if (_hasMore) {
          _page++;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      debugPrint('[ERROR] Lỗi tải báo cáo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToUpdateScreen(Report report) async {
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
    // If the update screen returns true, it means the report was updated successfully.
    if (result == true) {
      _fetchReports(isRefresh: true); // Refresh the list
    }
  }

  void _handleItemTap(Report report) {
    if (report.status == ReportStatus.needsUpdate) {
      _navigateToUpdateScreen(report);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(report: report),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử báo cáo'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    // Chỉ hiển thị các trạng thái có dữ liệu thực tế (ẩn các tab rỗng)
    final availableStatuses = ReportStatus.values.where((status) {
      if (_allReports.isEmpty) return true; // Khi đang tải thì hiển thị tất cả
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

    // Đếm số lượng báo cáo cho từng trạng thái
    String displayLabel = label;
    if (_allReports.isNotEmpty) {
      final count = status == null
          ? _allReports.length
          : _allReports.where((r) => r.status == status).length;
      displayLabel = '$label ($count)';
    }

    return GestureDetector(
      onTap: () => _applyFilter(status),
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

  Widget _buildBody() {
    if (_reports.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _reports.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lỗi tải dữ liệu:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchReports(isRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Không có báo cáo trong mục này',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchReports(isRefresh: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _reports.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _reports.length) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            ));
          }
          final report = _reports[index];
          return _ReportListItem(
            report: report,
            onTap: () => _handleItemTap(report),
          );
        },
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ReportListItem({
    required this.report,
    required this.onTap,
  });

  Widget _buildImage() {
    String? imageUrl = report.imageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            imageUrl,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }

      // Handle both absolute and relative URLs from the server
      final String finalImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '${ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '')}/${imageUrl.replaceAll(RegExp(r'^/'), '')}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          finalImageUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        height: 70,
        color: Colors.grey.shade200,
        child:
            const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      ),
    );
  }

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (report.reportNo != null &&
                            report.reportNo!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Text(
                              report.reportNo!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (report.reportType != null &&
                            report.reportType!.isNotEmpty)
                          Text(
                            'Loại: ${report.reportType}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description ?? 'Không có mô tả.',
                      style: TextStyle(
                          color: report.description != null
                              ? Colors.black54
                              : Colors.grey,
                          fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            report.submitDate != null
                                ? 'Nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(report.submitDate!.toLocal())}'
                                : 'Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt.toLocal())}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (report.workerName != null &&
                        report.workerName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('Người tạo: ${report.workerName}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    if (report.status == ReportStatus.needsUpdate &&
                        report.ownerComment != null &&
                        report.ownerComment!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.comment_outlined,
                                size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('Lý do: ${report.ownerComment!}',
                                    style:
                                        TextStyle(color: Colors.red.shade800))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildImage(),
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

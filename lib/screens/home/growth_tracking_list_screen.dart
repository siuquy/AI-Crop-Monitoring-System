import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/service/growth_tracking_service.dart';
import '../../models/growth_tracking.dart';
import 'growth_tracking_detail_screen.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class GrowthTrackingListScreen extends StatefulWidget {
  final String farmId;
  final String plotId;
  final String bedId;
  final String seasonId;
  final String farmName;
  final String plotName;
  final String bedName;
  final String seasonName;

  const GrowthTrackingListScreen({
    super.key,
    required this.farmId,
    required this.plotId,
    required this.bedId,
    required this.seasonId,
    required this.farmName,
    required this.plotName,
    required this.bedName,
    required this.seasonName,
  });

  @override
  State<GrowthTrackingListScreen> createState() =>
      _GrowthTrackingListScreenState();
}

class _GrowthTrackingListScreenState extends State<GrowthTrackingListScreen> {
  List<GrowthTracking> _trackings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrackings();
  }

  Future<void> _fetchTrackings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trackings = await GrowthTrackingService.getGrowthTrackings();

      // Lọc danh sách theo bedName (hoặc theo tiêu chí đã chọn)
      final filteredTrackings =
          trackings.where((t) => t.bedName == widget.bedName).toList();

      // Sắp xếp giảm dần theo ngày cập nhật mới nhất
      filteredTrackings.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime.now();
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _trackings = filteredTrackings;
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
        title: const Text('Danh sách theo dõi sinh trưởng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              '${widget.farmName} > ${widget.plotName} > ${widget.bedName}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryTeal,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GrowthTrackingDetailScreen(
                farmId: widget.farmId,
                plotId: widget.plotId,
                bedId: widget.bedId,
                seasonId: widget.seasonId,
                farmName: widget.farmName,
                plotName: widget.plotName,
                bedName: widget.bedName,
                seasonName: widget.seasonName,
                tracking: null,
              ),
            ),
          );
          if (result == true) {
            _fetchTrackings(); // Reload lại danh sách sau khi cập nhật
          }
        },
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm mới',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
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
              onPressed: _fetchTrackings,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_trackings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Chưa có dữ liệu sinh trưởng nào.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTrackings,
      color: primaryTeal,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _trackings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final tracking = _trackings[index];
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
                    _fetchTrackings(); // Reload lại danh sách sau khi cập nhật
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
        },
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

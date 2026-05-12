import 'package:acmms/core/service/growth_tracking_service.dart';
import 'package:acmms/models/growth_tracking.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color bgColor = Color(0xFFF0F8F1);

class GrowthTrackingScreen extends StatefulWidget {
  const GrowthTrackingScreen({super.key});

  @override
  State<GrowthTrackingScreen> createState() => _GrowthTrackingScreenState();
}

class _GrowthTrackingScreenState extends State<GrowthTrackingScreen> {
  late Future<List<GrowthTracking>> _trackingsFuture;

  @override
  void initState() {
    super.initState();
    _trackingsFuture = GrowthTrackingService.getGrowthTrackings();
  }

  void _refresh() {
    setState(() {
      _trackingsFuture = GrowthTrackingService.getGrowthTrackings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Theo dõi sinh trưởng',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<GrowthTracking>>(
        future: _trackingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi tải dữ liệu:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final trackings = snapshot.data ?? [];

          if (trackings.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu theo dõi nào.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trackings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final tracking = trackings[index];
              return _buildTrackingCard(tracking);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackingCard(GrowthTracking tracking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryTeal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.spoke_rounded,
                    color: primaryTeal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tracking.cropName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                        _statusBadge(tracking.trackingStatus),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Giai đoạn: ${tracking.stageName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow(Icons.location_on_outlined, 'Luống', tracking.bedName),
          if (tracking.startDate != null)
            _infoRow(Icons.calendar_today_outlined, 'Bắt đầu',
                DateFormat('dd/MM/yyyy').format(tracking.startDate!)),
          if (tracking.lastObservedAt != null)
            _infoRow(
                Icons.access_time_filled_outlined,
                'Cập nhật gần nhất',
                DateFormat('dd/MM/yyyy, HH:mm')
                    .format(tracking.lastObservedAt!)),
          if (tracking.healthStatus != null)
            _infoRow(Icons.health_and_safety_outlined, 'Sức khỏe',
                tracking.healthStatus!,
                valueColor: tracking.healthStatus?.toLowerCase() == 'ok'
                    ? Colors.green
                    : Colors.red),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(TrackingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
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
}

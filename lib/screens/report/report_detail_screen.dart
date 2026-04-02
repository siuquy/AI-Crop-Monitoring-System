import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import '../../models/report_status.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết báo cáo'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF3F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  icon: Icons.title,
                  label: 'Tiêu đề:',
                  value: report.title,
                  isTitle: true,
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.person_outline,
                  label: 'Người tạo:',
                  value: report.workerName ?? 'Không xác định',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.description_outlined,
                  label: 'Mô tả:',
                  value: report.description ?? 'Không có mô tả chi tiết.',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.bug_report_outlined,
                  label: 'Tên bệnh (nếu có):',
                  value: report.diseaseName ?? 'Không có',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ngày tạo:',
                  value:
                      DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                ),
                const SizedBox(height: 16),
                _buildStatusRow(report.status),
                if (report.ownerComment != null &&
                    report.ownerComment!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.comment_outlined,
                    label: 'Nhận xét:',
                    value: report.ownerComment!,
                    isComment: true,
                  ),
                ],
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    icon: Icons.image_outlined,
                    label: 'Hình ảnh đính kèm:',
                    value: '', // Value is handled by the custom widget below
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        report.imageUrl!,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator()),
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 48, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isTitle = false,
    bool isComment = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 28.0), // Căn chỉnh với icon
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTitle ? 18 : 16,
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
                color: isComment ? Colors.red.shade700 : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusRow(ReportStatus status) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          'Trạng thái:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        _StatusTag(status: status), // Sử dụng lại StatusTag từ ReportListScreen
      ],
    );
  }
}

// _StatusTag cần được định nghĩa lại hoặc import từ report_list_screen.dart
// Để đơn giản, tôi sẽ định nghĩa lại ở đây. Trong thực tế, bạn nên tạo một widget riêng.
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import '../../models/report_status.dart';
import '../../core/service/report_service.dart';

const Color primaryTeal = Color(0xFF4CAF50);
const Color darkTeal = Color(0xFF388E3C);
const Color bgColor = Color(0xFFF0F8F1);

class ReportDetailScreen extends StatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<List<dynamic>> _attachmentsFuture;

  @override
  void initState() {
    super.initState();
    _attachmentsFuture = ReportService.getAttachments(
      objectId: widget.report.id,
      objectType: 'report',
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    String rawDescription = report.description ?? 'Không có mô tả chi tiết.';
    String? severity;
    String detailedDesc = rawDescription;

    if (rawDescription.startsWith('Mức độ nghiêm trọng:')) {
      final parts = rawDescription.split('\n\n');
      if (parts.length > 1) {
        severity = parts[0].replaceAll('Mức độ nghiêm trọng:', '').trim();
        detailedDesc = parts.sublist(1).join('\n\n').trim();
      } else {
        final newlineIndex = rawDescription.indexOf('\n');
        if (newlineIndex != -1) {
          severity = rawDescription
              .substring(0, newlineIndex)
              .replaceAll('Mức độ nghiêm trọng:', '')
              .trim();
          detailedDesc = rawDescription.substring(newlineIndex).trim();
        } else {
          severity =
              rawDescription.replaceAll('Mức độ nghiêm trọng:', '').trim();
          detailedDesc = 'Không có nội dung mô tả.';
        }
      }
    }

    Color sevColor = Colors.grey.shade700;
    Color sevBgColor = Colors.grey.shade50;
    if (severity != null) {
      final s = severity.toLowerCase();
      if (s.contains('cao')) {
        sevColor = Colors.red.shade700;
        sevBgColor = Colors.red.shade50;
      } else if (s.contains('trung bình')) {
        sevColor = Colors.orange.shade700;
        sevBgColor = Colors.orange.shade50;
      } else if (s.contains('thấp')) {
        sevColor = Colors.blue.shade700;
        sevBgColor = Colors.blue.shade50;
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Chi tiết báo cáo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<dynamic>>(
              future: _attachmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 260,
                    child: Center(
                        child: CircularProgressIndicator(color: primaryTeal)),
                  );
                }

                final attachments = snapshot.data ?? [];
                if (attachments.isNotEmpty) {
                  return _buildAttachmentsCarousel(attachments);
                }

                if (report.imageUrl != null && report.imageUrl!.isNotEmpty) {
                  return _buildImageHeader(report.imageUrl!);
                }
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(status: report.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _buildMetaItem(Icons.calendar_today_rounded,
                          'Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}'),
                      _buildMetaItem(Icons.person_rounded,
                          report.workerName ?? 'Không xác định'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGeneralInfoCard(),
                  const SizedBox(height: 24),
                  if (report.diseaseName != null &&
                      report.diseaseName!.isNotEmpty) ...[
                    _buildInfoCard(
                        icon: Icons.bug_report_rounded,
                        title: 'Tên bệnh phát hiện',
                        value: report.diseaseName!,
                        color: Colors.orange.shade700,
                        bgColor: Colors.orange.shade50),
                    const SizedBox(height: 16),
                  ],
                  if (severity != null) ...[
                    _buildInfoCard(
                      icon: Icons.warning_rounded,
                      title: 'Mức độ nghiêm trọng',
                      value: severity,
                      color: sevColor,
                      bgColor: sevBgColor,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if ((report.diseaseName == null ||
                          report.diseaseName!.isEmpty) &&
                      severity == null)
                    const SizedBox(height: 24),
                  if (report.aiResults != null) ...[
                    const Text(
                      'Phân tích chi tiết từ AI',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildAiResultsCard(report.aiResults!),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Mô tả chi tiết',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      detailedDesc.isEmpty
                          ? 'Không có mô tả chi tiết.'
                          : detailedDesc,
                      style: const TextStyle(
                          fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                  ),
                  if (report.ownerComment != null &&
                      report.ownerComment!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Nhận xét từ Quản lý',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.feedback_rounded,
                              color: Colors.red.shade600, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              report.ownerComment!,
                              style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: primaryTeal)),
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildAttachmentsCarousel(List<dynamic> attachments) {
    if (attachments.length == 1) {
      final url = attachments[0]['secureUrl'] ?? attachments[0]['fileUrl'];
      if (url != null) return _buildImageHeader(url);
    }

    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final url =
              attachments[index]['secureUrl'] ?? attachments[index]['fileUrl'];
          if (url == null) return const SizedBox();
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) =>
                    loadingProgress == null
                        ? child
                        : const Center(
                            child:
                                CircularProgressIndicator(color: primaryTeal)),
                errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${index + 1}/${attachments.length}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                )
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResultsCard(Map<String, dynamic> aiData) {
    final confidence = aiData['confidence'];
    final symptoms = aiData['symptoms'] as List<dynamic>?;
    final treatment = aiData['treatment'] as List<dynamic>?;
    final aiDesc = aiData['description']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (confidence != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: darkTeal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Độ tin cậy: ${(double.parse(confidence.toString()) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: darkTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (symptoms != null && symptoms.isNotEmpty) ...[
            Text('Triệu chứng:',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 6),
            ...symptoms.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                              color: darkTeal, fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(s.toString(),
                              style: const TextStyle(
                                  color: Colors.black87, height: 1.4))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
          ],
          if (treatment != null && treatment.isNotEmpty) ...[
            Text('Cách xử lý đề xuất:',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 6),
            ...treatment.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                              color: darkTeal, fontWeight: FontWeight.bold)),
                      Expanded(
                          child: Text(t.toString(),
                              style: const TextStyle(
                                  color: Colors.black87, height: 1.4))),
                    ],
                  ),
                )),
          ],
          if (aiDesc != null &&
              aiDesc.isNotEmpty &&
              (symptoms == null || symptoms.isEmpty))
            Text(aiDesc,
                style: const TextStyle(color: Colors.black87, height: 1.5))
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin chung',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const Divider(height: 24, color: Colors.black12),
          _buildInfoRow(
              'Mã báo cáo:', widget.report.reportNo ?? 'Đang cập nhật'),
          _buildInfoRow(
              'Loại báo cáo:', widget.report.reportType ?? 'Không xác định'),
          _buildInfoRow(
              'Người quản lý:', widget.report.ownerName ?? 'Chưa phân công'),
          _buildInfoRow(
              'Ngày nộp:',
              widget.report.submitDate != null
                  ? DateFormat('dd/MM/yyyy HH:mm')
                      .format(widget.report.submitDate!.toLocal())
                  : 'Chưa cập nhật'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
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
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'report_update_screen.dart';
import '../../models/report_status.dart';
import '../../screens/task/api_config.dart';

class ReportViewDetailScreen extends StatelessWidget {
  final String reportId;
  final String imagePath;
  final String title;
  final String diseaseName;
  final String level;
  final String date;
  final ReportStatus status;
  final String ownerComment;

  const ReportViewDetailScreen({
    super.key,
    required this.reportId,
    required this.imagePath,
    required this.title,
    required this.diseaseName,
    required this.level,
    required this.date,
    required this.status,
    this.ownerComment =
        "Cần cung cấp thêm hình ảnh rõ hơn và mô tả chi tiết khu vực bị bệnh.",
  });

  Color getStatusColor() {
    return status.color;
  }

  String getStatusText() {
    return status.displayName;
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          )
        ],
      ),
    );
  }

  Widget buildStatusBadge() {
    final color = getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        getStatusText(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget buildExpertComment() {
    if (status != ReportStatus.needsUpdate) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ownerComment,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUpdateButton(BuildContext context) {
    if (status != ReportStatus.needsUpdate) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReportUpdateScreen(
                  reportId: reportId,
                  imagePath: imagePath,
                  title: title,
                  diseaseName: diseaseName,
                  ownerComment: ownerComment,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "Bổ sung báo cáo",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget buildImage() {
    if (imagePath.isEmpty) {
      return Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.image_not_supported_outlined,
            color: Colors.grey, size: 48),
      );
    }

    if (imagePath.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          imagePath,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
        ),
      );
    }

    final String finalImageUrl = imagePath.startsWith('http')
        ? imagePath
        : '${ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '')}/${imagePath.replaceAll(RegExp(r'^/'), '')}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        finalImageUrl,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Chi tiết báo cáo"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildImage(),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            buildInfoRow("Loại bệnh", diseaseName),
            buildInfoRow("Mức độ", level),
            buildInfoRow("Thời gian", date),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  "Trạng thái: ",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                buildStatusBadge(),
              ],
            ),
            buildExpertComment(),
            buildUpdateButton(context),
          ],
        ),
      ),
    );
  }
}

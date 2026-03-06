import 'dart:io';
import 'package:flutter/material.dart';
import 'package:acmms/screens/report/report_detail_screen.dart';
import 'report_screen.dart';

class ReportViewDetailScreen extends StatelessWidget {
  final String imagePath;
  final String title;
  final String diseaseName;
  final String level;
  final String date;
  final ReportStatus status;
  final String? ownerComment;

  const ReportViewDetailScreen({
    super.key,
    required this.imagePath,
    required this.title,
    required this.diseaseName,
    required this.level,
    required this.date,
    required this.status,
    this.ownerComment,
  });

  bool get isApproved => status == ReportStatus.approved;

  bool get needMoreInfo => status == ReportStatus.needMoreInfo;

  bool get isPending => status == ReportStatus.pending;

  Color _getLevelColor(String level) {
    switch (level) {
      case "Nhẹ":
        return Colors.green;
      case "Trung bình":
        return Colors.orange;
      case "Nghiêm trọng":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.green;
      case ReportStatus.needMoreInfo:
        return Colors.purple;
    }
  }

  String _getStatusText() {
    switch (status) {
      case ReportStatus.pending:
        return "Đang chờ duyệt";
      case ReportStatus.approved:
        return "Đã duyệt";
      case ReportStatus.needMoreInfo:
        return "Yêu cầu bổ sung";
    }
  }

  Widget _buildImage() {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      );
    } else {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      );
    }
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
        )
      ],
    );
  }

  String _buttonText() {
    if (needMoreInfo) {
      return "Bổ sung báo cáo";
    }

    if (isPending) {
      return "Đang chờ duyệt";
    }

    return "Tạo báo cáo";
  }

  bool _disableButton() {
    if (status == ReportStatus.approved) return true;
    if (status == ReportStatus.pending) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Chi tiết báo cáo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _boxDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImage(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _boxDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Kết quả phân tích",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(diseaseName),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getLevelColor(level).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              level,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getLevelColor(level),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (needMoreInfo && ownerComment != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Yêu cầu bổ sung từ Owner",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(ownerComment!),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _boxDecoration(),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Khuyến nghị xử lý",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text("• Phun thuốc phù hợp"),
                          SizedBox(height: 4),
                          Text("• Theo dõi 3 ngày tiếp theo"),
                          SizedBox(height: 4),
                          Text("• Kiểm tra khu vực lân cận"),
                          SizedBox(height: 4),
                          Text("• Báo lại nếu lan rộng"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _disableButton()
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportDetailScreen(
                                      imagePath: imagePath,
                                      diseaseName: diseaseName,
                                      confidence: 0.92,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _disableButton() ? Colors.grey : Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _buttonText(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

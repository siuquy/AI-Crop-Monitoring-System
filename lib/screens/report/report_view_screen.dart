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

  const ReportViewDetailScreen({
    super.key,
    required this.imagePath,
    required this.title,
    required this.diseaseName,
    required this.level,
    required this.date,
    required this.status,
  });

  bool get isApproved => status == ReportStatus.approved;

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

  /// ✅ Tự động xử lý image Asset hoặc File
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),


      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
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

                    /// TITLE CARD
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// IMAGE
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildImage(),
                    ),

                    const SizedBox(height: 16),

                    /// RESULT CARD
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

                    /// RECOMMENDATION CARD
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

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isApproved
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
                              isApproved ? Colors.grey : Colors.teal,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Tạo báo cáo",
                          style: TextStyle(
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
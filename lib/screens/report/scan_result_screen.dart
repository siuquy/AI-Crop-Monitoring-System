import 'dart:io';
import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  final String imagePath;
  final String diseaseName;
  final double confidence;

  final String farm;
  final String field;
  final String area;
  final String row;

  final DateTime captureTime;

  ScanResultScreen({
    super.key,
    this.imagePath = '',
    this.diseaseName = '',
    this.confidence = 0,
    this.farm = '',
    this.field = '',
    this.area = '',
    this.row = '',
    DateTime? captureTime,
  }) : captureTime = captureTime ?? DateTime.now();

  Widget locationItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        )
      ],
    );
  }

  String formatTime(DateTime time) {
    return "${time.day}/${time.month}/${time.year} "
        "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả quét"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            /// TIME DISPLAY
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  formatTime(captureTime),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// RESULT CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Chẩn đoán bệnh",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diseaseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text("Cà chua"),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(confidence * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// LOCATION TITLE
            const Text(
              "📍 Vị trí phát hiện",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            /// LOCATION CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: locationItem("Trang trại", farm)),
                      Expanded(child: locationItem("Ruộng", field)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: locationItem("Khu", area)),
                      Expanded(child: locationItem("Luống", row)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// AI DESCRIPTION
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Phát hiện các đốm bất thường trên lá có hình tròn và màu sẫm – "
                "đặc trưng của bệnh $diseaseName.\n\n"
                "AI khuyến nghị kiểm tra và xử lý sớm để tránh lây lan.",
              ),
            ),

            const SizedBox(height: 30),

            /// REPORT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text("Tạo báo cáo"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Báo cáo đã được tạo"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

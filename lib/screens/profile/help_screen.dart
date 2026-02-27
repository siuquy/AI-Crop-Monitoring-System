import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF1FCFC5);
const Color darkGreen = Color(0xFF2E7D32);
const Color lightGreenBg = Color(0xFFE8F5E9);

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text('Hướng dẫn sử dụng'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 24),
          _timelineItem(
            number: 1,
            title: 'Nhận công việc',
            content: 'Vào tab Công việc để xem danh sách nhiệm vụ trong ngày. '
                'Những việc khẩn cấp sẽ được đánh dấu nổi bật để ưu tiên xử lý.',
          ),
          _timelineItem(
            number: 2,
            title: 'Xem chi tiết',
            content:
                'Nhấn vào công việc để xem loại cây trồng, khu vực và hướng dẫn cụ thể. '
                'Đọc kỹ yêu cầu trước khi bắt đầu.',
          ),
          _timelineItem(
            number: 3,
            title: 'Thực hiện công việc',
            content:
                'Tiến hành công việc theo kế hoạch. Bạn có thể cập nhật tiến độ trong quá trình làm việc.',
          ),
          _timelineItem(
            number: 4,
            title: 'Thêm ảnh minh chứng',
            content:
                'Chụp ảnh ruộng, cây trồng hoặc kết quả sau khi hoàn thành. '
                'Ảnh giúp quản lý theo dõi tốt hơn.',
          ),
          _timelineItem(
            number: 5,
            title: 'Hoàn thành',
            content:
                'Nhấn nút "Đánh dấu hoàn thành". Công việc sẽ được lưu lại và không thể chỉnh sửa.',
          ),
          _timelineItem(
            number: 6,
            title: 'Kiểm tra lịch sử',
            content:
                'Xem lại các công việc đã làm để đánh giá hiệu quả theo thời gian.',
          ),
          _timelineItem(
            number: 7,
            title: 'Xử lý sự cố',
            content:
                'Nếu gặp sự cố (sâu bệnh, hư hỏng thiết bị…), hãy cập nhật ghi chú hoặc liên hệ quản lý.',
            isWarning: true,
          ),
          const SizedBox(height: 24),
          _supportSection(),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryTeal],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quy trình làm việc',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Thực hiện theo 7 bước dưới đây để quản lý công việc hiệu quả trên trang trại.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required int number,
    required String title,
    required String content,
    bool isWarning = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isWarning ? Colors.red : primaryTeal,
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWarning ? const Color(0xFFFFEBEE) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isWarning
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: isWarning ? Colors.red : primaryTeal,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportSection() {
    return Column(
      children: [
        const Text(
          'Bạn vẫn cần trợ giúp?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.support_agent),
          label: const Text('Liên hệ hỗ trợ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryTeal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        )
      ],
    );
  }
}

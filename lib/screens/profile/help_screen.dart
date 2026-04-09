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
          // _timelineItem(
          //   number: 7,
          //   title: 'Xử lý sự cố',
          //   content:
          //       'Nếu gặp sự cố (sâu bệnh, hư hỏng thiết bị…), hãy cập nhật ghi chú hoặc liên hệ quản lý.',
          //   isWarning: true,
          //   isLast: true,
          // ),
          const SizedBox(height: 24),
          // _supportSection(),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkGreen, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy trình làm việc',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Thực hiện theo 6 bước dưới đây để quản lý công việc hiệu quả trên trang trại.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.playlist_add_check_rounded,
              color: Colors.white.withOpacity(0.8), size: 50),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required int number,
    required String title,
    required String content,
    bool isWarning = false,
    bool isLast = false,
  }) {
    final Color color = isWarning ? Colors.red.shade700 : primaryTeal;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: color, width: 5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: lightGreenBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent_rounded,
            size: 40,
            color: darkGreen,
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn vẫn cần trợ giúp?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đừng ngần ngại liên hệ với đội ngũ hỗ trợ của chúng tôi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement contact support action
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text(
              'Liên hệ hỗ trợ',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              elevation: 5,
              shadowColor: primaryTeal.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hướng dẫn sử dụng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpItem(
            title: '1. Nhận công việc',
            content:
                'Vào tab Công việc để xem danh sách các công việc được giao trong ngày hoặc sắp tới. '
                'Những công việc khẩn cấp sẽ được đánh dấu nổi bật để bạn ưu tiên xử lý.',
          ),
          _HelpItem(
            title: '2. Xem chi tiết công việc',
            content:
                'Nhấn vào một công việc để xem chi tiết như: loại công việc, cây trồng, khu vực, '
                'thời gian dự kiến và người giao việc. '
                'Hãy đọc kỹ hướng dẫn trước khi bắt đầu.',
          ),
          _HelpItem(
            title: '3. Thực hiện công việc',
            content:
                'Trong quá trình làm việc, bạn có thể cập nhật mô tả ngắn về tiến độ, '
                'chụp ảnh hiện trạng hoặc kết quả để lưu lại.',
          ),
          _HelpItem(
            title: '4. Thêm hình ảnh minh chứng',
            content:
                'Nhấn vào mục thêm ảnh trong màn hình chi tiết công việc để chụp ảnh ruộng, cây trồng '
                'hoặc kết quả sau khi hoàn thành. Ảnh giúp quản lý và chủ trang trại theo dõi công việc tốt hơn.',
          ),
          _HelpItem(
            title: '5. Đánh dấu hoàn thành',
            content:
                'Sau khi hoàn thành công việc, nhấn nút "Đánh dấu hoàn thành". '
                'Công việc sẽ được lưu lại vào lịch sử và không thể chỉnh sửa nữa.',
          ),
          _HelpItem(
            title: '6. Kiểm tra lịch sử công việc',
            content:
                'Các công việc đã hoàn thành sẽ được lưu để bạn và quản lý theo dõi. '
                'Điều này giúp đánh giá hiệu quả làm việc theo thời gian.',
          ),
          _HelpItem(
            title: '7. Xử lý sự cố',
            content:
                'Nếu gặp sự cố như không thực hiện được công việc hoặc phát hiện vấn đề bất thường '
                '(sâu bệnh, hư hỏng thiết bị…), hãy cập nhật ghi chú hoặc liên hệ quản lý.',
          ),
          _HelpItem(
            title: '8. Tài khoản & bảo mật',
            content:
                'Tài khoản do chủ trang trại cấp. Không chia sẻ mật khẩu cho người khác. '
                'Nếu quên mật khẩu, hãy liên hệ quản lý để được hỗ trợ.',
          ),
          _HelpItem(
            title: '9. Hỗ trợ kỹ thuật',
            content:
                'Nếu ứng dụng gặp lỗi hoặc không sử dụng được, hãy liên hệ bộ phận hỗ trợ '
                'hoặc quản lý trang trại để được xử lý kịp thời.',
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String content;

  const _HelpItem({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

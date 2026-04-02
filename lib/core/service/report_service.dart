import '../../data/mock_reports.dart';
import '../../models/report.dart';

class ReportService {
  /// Lấy danh sách các báo cáo.
  /// Trong ứng dụng thực tế, phương thức này sẽ gọi ApiClient để lấy dữ liệu từ server.
  static Future<List<Report>> getReports() async {
    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(seconds: 1));

    // Trả về dữ liệu giả lập
    // Trong tương lai, bạn sẽ thay thế dòng này bằng:
    // final data = await ApiClient.instance.get('/api/reports');
    return MockReports.reports;
  }
}

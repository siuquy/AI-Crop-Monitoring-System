import '../models/report.dart';
import '../models/report_status.dart';

class MockReports {
  static final List<Report> reports = [
    Report(
      id: 'report_1',
      title: 'Báo cáo sâu bệnh hại lúa',
      diseaseName: 'Bệnh đạo ôn',
      imageUrl: 'assets/images/placeholder.png', // Sử dụng ảnh placeholder
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ReportStatus.approved,
    ),
    Report(
      id: 'report_2',
      title: 'Kiểm tra tình trạng cà chua',
      diseaseName: 'Bệnh đốm lá',
      imageUrl: 'assets/images/placeholder.png',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      status: ReportStatus.pending,
    ),
    Report(
      id: 'report_3',
      title: 'Báo cáo về cây ngô',
      diseaseName: 'Sâu đục thân',
      imageUrl: 'assets/images/placeholder.png',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: ReportStatus.needsUpdate,
      ownerComment:
          'Ảnh chụp bị mờ, không thấy rõ tình trạng sâu bệnh. Vui lòng chụp lại ảnh rõ nét hơn ở khu vực bị ảnh hưởng nặng nhất.',
    ),
    Report(
      id: 'report_4',
      title: 'Tình hình phát triển của bắp cải',
      diseaseName: 'Khỏe mạnh',
      imageUrl: 'assets/images/placeholder.png',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ReportStatus.approved,
    ),
  ];
}

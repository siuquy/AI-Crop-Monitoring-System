import '../models/report.dart';
import '../models/report_status.dart';

class MockReports {
  static final List<Report> reports = [
    Report(
      id: 'report_1',
      title: 'Báo cáo sâu bệnh hại lúa',
      diseaseName: 'Bệnh đạo ôn',
      description: 'Phát hiện bệnh đạo ôn trên diện rộng tại khu A.',
      imageUrl: 'assets/images/placeholder.png', // Sử dụng ảnh placeholder
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: ReportStatus.approved,
      workerName: 'Nguyễn Văn A',
    ),
    Report(
      id: 'report_2',
      title: 'Kiểm tra tình trạng cà chua',
      diseaseName: 'Bệnh đốm lá',
      description: 'Cà chua có dấu hiệu bệnh đốm lá, cần xử lý.',
      imageUrl: 'assets/images/placeholder.png',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      status: ReportStatus.pending,
      workerName: 'Trần Thị B',
    ),
    Report(
      id: 'report_3',
      title: 'Báo cáo về cây ngô',
      diseaseName: 'Sâu đục thân',
      description: 'Sâu đục thân gây hại trên cây ngô.',
      imageUrl: 'assets/images/placeholder.png',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: ReportStatus.needsUpdate,
      ownerComment:
          'Ảnh chụp bị mờ, không thấy rõ tình trạng sâu bệnh. Vui lòng chụp lại ảnh rõ nét hơn ở khu vực bị ảnh hưởng nặng nhất.',
      workerName: 'Lê Văn C',
    ),
    Report(
      id: 'report_4',
      title: 'Tình hình phát triển của bắp cải',
      diseaseName: 'Khỏe mạnh',
      description: 'Bắp cải phát triển tốt, không có dấu hiệu sâu bệnh.',
      imageUrl: 'assets/images/placeholder.png',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: ReportStatus.approved,
      workerName: 'Phạm Thị D',
    ),
  ];
}

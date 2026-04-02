import 'report_status.dart';

class Report {
  final String id;
  final String title;
  final String diseaseName;
  final String imageUrl; // Có thể là URL hoặc đường dẫn asset
  final DateTime createdAt;
  final ReportStatus status;
  final String? ownerComment; // Nhận xét từ chuyên gia khi cần bổ sung

  Report({
    required this.id,
    required this.title,
    required this.diseaseName,
    required this.imageUrl,
    required this.createdAt,
    required this.status,
    this.ownerComment,
  });
}

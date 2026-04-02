import 'report_status.dart';

class Report {
  final String id;
  final String title;
  final String? description;
  final String? diseaseName;
  final String? imageUrl; // Có thể là URL hoặc đường dẫn asset
  final DateTime createdAt;
  final ReportStatus status;
  final String? ownerComment; // Nhận xét từ chuyên gia khi cần bổ sung
  final String? workerName;

  Report({
    required this.id,
    required this.title,
    this.description,
    this.diseaseName,
    this.imageUrl,
    required this.createdAt,
    required this.status,
    this.ownerComment,
    this.workerName,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    ReportStatus status;
    // Ánh xạ chuỗi trạng thái từ API sang enum ReportStatus
    switch (json['status']?.toString().toLowerCase()) {
      case 'active':
      case 'approved':
        status = ReportStatus.approved;
        break;
      case 'pending':
        status = ReportStatus.pending;
        break;
      case 'needsupdate':
        status = ReportStatus.needsUpdate;
        break;
      default:
        status = ReportStatus.pending;
    }

    return Report(
      id: json['reportId'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      status: status,
      workerName: json['workerName'],
      imageUrl: json['imageUrl'],
      diseaseName: json['diseaseName'],
      ownerComment: json['ownerComment'],
    );
  }
}

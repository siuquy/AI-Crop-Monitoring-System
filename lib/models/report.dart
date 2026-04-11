import 'dart:convert';
import 'report_status.dart';

class Report {
  final String id;
  final String title;
  final String? description;
  final String? diseaseName;
  final String? imageUrl;
  final DateTime createdAt;
  final ReportStatus status;
  final String? ownerComment;
  final String? workerName;
  final Map<String, dynamic>? aiResults;

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
    this.aiResults,
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

    Map<String, dynamic>? parsedAiResults;
    String? cleanDescription = json['description'];

    if (json['aiResultsJson'] != null &&
        json['aiResultsJson'].toString().isNotEmpty) {
      try {
        parsedAiResults = jsonDecode(json['aiResultsJson']);
      } catch (e) {
        // Bỏ qua lỗi nếu JSON không hợp lệ
      }
    }

    if (parsedAiResults == null &&
        cleanDescription != null &&
        cleanDescription.contains('---AI_RESULT_JSON---')) {
      final parts = cleanDescription.split('---AI_RESULT_JSON---');
      cleanDescription = parts[0].trim();
      if (parts.length > 1) {
        try {
          parsedAiResults = jsonDecode(parts[1].trim());
        } catch (e) {}
      }
    }

    return Report(
      id: json['reportId'],
      title: json['title'],
      description: cleanDescription,
      createdAt: DateTime.parse(json['createdAt']),
      status: status,
      workerName: json['workerName'],
      imageUrl: json['imageUrl'],
      diseaseName: json['diseaseName'],
      ownerComment: json['ownerComment'],
      aiResults: parsedAiResults,
    );
  }
}

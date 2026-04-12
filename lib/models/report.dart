import 'dart:convert';
import 'report_status.dart';

class Report {
  final String id;
  final String? reportNo;
  final String title;
  final String? description;
  final String? reportType;
  final String? createdBy;
  final String? creatorName;
  final String? ownerId;
  final String? ownerName;
  final String? plotId;
  final String? bedId;
  final String? seasonId;
  final String? diseaseName;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? submitDate;
  final DateTime? updatedAt;
  final ReportStatus status;
  final String? ownerComment;
  final String? workerName;
  final Map<String, dynamic>? aiResults;
  final String? aiResultsJson;

  Report({
    required this.id,
    this.reportNo,
    required this.title,
    this.description,
    this.reportType,
    this.createdBy,
    this.creatorName,
    this.ownerId,
    this.ownerName,
    this.plotId,
    this.bedId,
    this.seasonId,
    this.diseaseName,
    this.imageUrl,
    required this.createdAt,
    this.submitDate,
    this.updatedAt,
    required this.status,
    this.ownerComment,
    this.workerName,
    this.aiResults,
    this.aiResultsJson,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    ReportStatus status;
    // Ánh xạ chuỗi trạng thái từ API sang enum ReportStatus
    switch (json['status']?.toString().toLowerCase()) {
      case 'active':
      case 'approved':
      case 'diagnosed':
        status = ReportStatus.approved;
        break;
      case 'pending':
      case 'assigned_for_diagnosis':
      case 'sent_to_owner':
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
      id: json['reportId'] ?? json['id'] ?? '',
      reportNo: json['reportNo'],
      title: json['title'] ?? 'Không có tiêu đề',
      description: cleanDescription,
      reportType: json['reportType'],
      createdBy: json['createdBy'],
      creatorName: json['creatorName'],
      ownerId: json['ownerId'],
      ownerName: json['ownerName'],
      plotId: json['plotId'],
      bedId: json['bedId'],
      seasonId: json['seasonId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      submitDate: json['submitDate'] != null
          ? DateTime.tryParse(json['submitDate'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      status: status,
      workerName: json['creatorName'] ?? json['workerName'],
      imageUrl: json['imageUrl'],
      diseaseName: json['diseaseName'] ?? parsedAiResults?['diseaseName'],
      ownerComment: json['ownerComment'],
      aiResults: parsedAiResults,
      aiResultsJson: json['aiResultsJson'],
    );
  }
}

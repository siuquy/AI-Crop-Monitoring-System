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
  final List<String> imageUrls;
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
    this.imageUrls = const [],
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
    switch (json['status']?.toString().toLowerCase().trim()) {
      case 'active':
      case 'approved':
        status = ReportStatus.approved;
        break;
      case 'diagnosed':
        status = ReportStatus.diagnosed;
        break;
      case 'pending':
        status = ReportStatus.pending;
        break;
      case 'assigned_for_diagnosis':
        status = ReportStatus.assignedForDiagnosis;
        break;
      case 'sent_to_owner':
        status = ReportStatus.sentToOwner;
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
      }
    }

    if (cleanDescription != null &&
        cleanDescription.contains('---AI_RESULT_JSON---')) {
      final parts = cleanDescription.split('---AI_RESULT_JSON---');
      cleanDescription = parts[0].trim();

      if (parsedAiResults == null && parts.length > 1) {
        try {
          parsedAiResults = jsonDecode(parts[1].trim());
        } catch (e) {}
      }
    }

    String? imgUrl = json['imageUrl'];
    List<String> urls = [];

    if (json['attachments'] != null && json['attachments'] is List) {
      for (var attachment in json['attachments']) {
        if (attachment is Map) {
          final url = attachment['secureUrl'] ?? attachment['fileUrl'];
          if (url != null) urls.add(url.toString());
        }
      }
    } else if (json['imageUrls'] != null && json['imageUrls'] is List) {
      urls = (json['imageUrls'] as List).map((e) => e.toString()).toList();
    }

    if (imgUrl == null && urls.isNotEmpty) {
      imgUrl = urls.first;
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
      imageUrl: imgUrl,
      imageUrls: urls,
      diseaseName: json['diseaseName'] ??
          parsedAiResults?['diseaseName'] ??
          parsedAiResults?['disease'],
      ownerComment: json['ownerComment'],
      aiResults: parsedAiResults,
      aiResultsJson: json['aiResultsJson'],
    );
  }
}

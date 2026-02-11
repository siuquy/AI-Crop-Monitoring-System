import 'report_status.dart';

class ReportModel {
  final String id;
  final String title;
  final String location;
  final String disease;
  final String time;
  final String imageAsset;
  final ReportStatus status;

  ReportModel({
    required this.id,
    required this.title,
    required this.location,
    required this.disease,
    required this.time,
    required this.imageAsset,
    required this.status,
  });
}

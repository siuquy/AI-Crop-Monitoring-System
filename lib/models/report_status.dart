import 'package:flutter/material.dart';

/// Enum định nghĩa các trạng thái của một báo cáo.
enum ReportStatus {
  pending, // Chờ duyệt
  approved, // Đã duyệt
  needsUpdate, // Cần bổ sung
}

/// Extension để cung cấp các thuộc tính tiện ích cho ReportStatus.
extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Chờ duyệt';
      case ReportStatus.approved:
        return 'Đã duyệt';
      case ReportStatus.needsUpdate:
        return 'Cần bổ sung';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return Colors.orange.shade700;
      case ReportStatus.approved:
        return Colors.green.shade700;
      case ReportStatus.needsUpdate:
        return Colors.red.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.pending:
        return Icons.hourglass_top_rounded;
      case ReportStatus.approved:
        return Icons.check_circle_outline_rounded;
      case ReportStatus.needsUpdate:
        return Icons.error_outline_rounded;
    }
  }
}

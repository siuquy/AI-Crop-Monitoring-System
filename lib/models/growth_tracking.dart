import 'package:flutter/material.dart';

enum TrackingStatus {
  inProgress,
  completed,
  pending,
  unknown;

  static TrackingStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'in-progress':
        return TrackingStatus.inProgress;
      case 'completed':
        return TrackingStatus.completed;
      case 'pending':
        return TrackingStatus.pending;
      default:
        return TrackingStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case TrackingStatus.inProgress:
        return 'Đang theo dõi';
      case TrackingStatus.completed:
        return 'Hoàn thành';
      case TrackingStatus.pending:
        return 'Chưa bắt đầu';
      case TrackingStatus.unknown:
        return 'Không rõ';
    }
  }

  Color get color {
    switch (this) {
      case TrackingStatus.inProgress:
        return Colors.blue.shade700;
      case TrackingStatus.completed:
        return Colors.green.shade700;
      case TrackingStatus.pending:
        return Colors.orange.shade700;
      case TrackingStatus.unknown:
        return Colors.grey.shade700;
    }
  }
}

class GrowthTracking {
  final String trackingId;
  final String stageName;
  final String cropName;
  final String bedName;
  final DateTime? startDate;
  final DateTime? endDate;
  final TrackingStatus trackingStatus;
  final String? healthStatus;
  final DateTime? lastObservedAt;

  GrowthTracking({
    required this.trackingId,
    required this.stageName,
    required this.cropName,
    required this.bedName,
    this.startDate,
    this.endDate,
    required this.trackingStatus,
    this.healthStatus,
    this.lastObservedAt,
  });

  factory GrowthTracking.fromJson(Map<String, dynamic> json) {
    return GrowthTracking(
      trackingId: json['trackingId'] as String,
      stageName: json['stageName'] as String,
      cropName: json['cropName'] as String,
      bedName: json['bedName'] as String,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      trackingStatus: TrackingStatus.fromString(json['trackingStatus']),
      healthStatus: json['healthStatus'] as String?,
      lastObservedAt: json['lastObservedAt'] != null
          ? DateTime.parse(json['lastObservedAt'])
          : null,
    );
  }
}

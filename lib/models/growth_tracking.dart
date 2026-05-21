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
  final String? harvestDetailId;
  final String? stageId;
  final String stageName;
  final String cropName;
  final String bedName;
  final DateTime? startDate;
  final DateTime? endDate;
  final TrackingStatus trackingStatus;
  final String? healthStatus;
  final double? actualHeight;
  final double? actualYield;
  final int? delayDays;
  final String? delayReason;
  final String? lastUpdatedBy;
  final DateTime? lastObservedAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GrowthTracking({
    required this.trackingId,
    this.harvestDetailId,
    this.stageId,
    required this.stageName,
    required this.cropName,
    required this.bedName,
    this.startDate,
    this.endDate,
    required this.trackingStatus,
    this.healthStatus,
    this.actualHeight,
    this.actualYield,
    this.delayDays,
    this.delayReason,
    this.lastUpdatedBy,
    this.lastObservedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory GrowthTracking.fromJson(Map<String, dynamic> json) {
    return GrowthTracking(
      trackingId: json['trackingId'] as String,
      harvestDetailId: json['harvestDetailId'] as String?,
      stageId: json['stageId'] as String?,
      stageName: json['stageName'] as String,
      cropName: json['cropName'] as String,
      bedName: json['bedName'] as String,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      trackingStatus: TrackingStatus.fromString(json['trackingStatus']),
      healthStatus: json['healthStatus'] as String?,
      actualHeight: (json['actualHeight'] as num?)?.toDouble(),
      actualYield: (json['actualYield'] as num?)?.toDouble(),
      delayDays: json['delayDays'] as int?,
      delayReason: json['delayReason'] as String?,
      lastUpdatedBy: json['lastUpdatedBy'] as String?,
      lastObservedAt: json['lastObservedAt'] != null
          ? DateTime.parse(json['lastObservedAt'])
          : null,
      notes: json['notes'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TaskStatus { doing, pending, completed, urgent }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String taskType;
  final String season;

  String cropName;
  String field;
  String area;
  String bed;

  // Detailed fields from API
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> bedIds;
  final List<String> plotIds;

  final String date;
  final TaskStatus status;
  final bool isUrgent;
  final String assignedBy;
  final String assignedRole;
  final IconData avatarIcon;
  final String imageAsset;

  final DateTime? taskScheduledAt;
  final String rawStatus;
  final String assignedToWorkerId;
  final String seasonId;
  final List<dynamic> taskDetails;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.taskType,
    required this.cropName,
    required this.season,
    required this.field,
    required this.area,
    required this.bed,
    this.startDate,
    this.endDate,
    required this.bedIds,
    required this.plotIds,
    required this.date,
    required this.status,
    required this.isUrgent,
    required this.assignedBy,
    required this.assignedRole,
    required this.avatarIcon,
    required this.imageAsset,
    this.taskScheduledAt,
    required this.rawStatus,
    required this.assignedToWorkerId,
    required this.seasonId,
    required this.taskDetails,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final scheduledAt = json['taskScheduledAt'] != null
        ? DateTime.tryParse(json['taskScheduledAt'])
        : null;
    final startDate =
        json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null;
    final endDate =
        json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null;

    final rawStatus = (json['taskStatus'] ?? '').toString().toLowerCase();
    final mappedStatus = _mapStatus(rawStatus);

    return TaskModel(
      id: (json['taskId'] ?? '').toString(),
      title: (json['taskTitle'] ?? 'Không có tiêu đề').toString(),
      description: (json['taskNotes'] ?? '').toString().isEmpty
          ? 'Không có ghi chú'
          : (json['taskNotes'] ?? '').toString(),
      taskType: 'Công việc',
      cropName: 'Chưa có dữ liệu',
      season: 'Chưa có dữ liệu',
      field: 'Chưa có dữ liệu',
      area: 'Chưa có dữ liệu',
      bed: '',
      startDate: startDate ?? scheduledAt,
      endDate: endDate,
      date: scheduledAt != null
          ? DateFormat('dd/MM/yyyy').format(scheduledAt.toLocal())
          : 'Chưa có lịch',
      status: mappedStatus,
      isUrgent: mappedStatus == TaskStatus.urgent,
      assignedBy: 'Hệ thống',
      assignedRole: 'Quản lý',
      avatarIcon: _mapIcon(rawStatus),
      imageAsset: 'assets/task/sick.jpg',
      taskScheduledAt: scheduledAt,
      rawStatus: rawStatus,
      assignedToWorkerId: (json['assignedToWorkerId'] ?? '').toString(),
      seasonId: (json['seasonId'] ?? '').toString(),
      bedIds: List<String>.from(json['bedIds'] ?? []),
      plotIds: List<String>.from(json['plotIds'] ?? []),
      taskDetails: (json['taskDetails'] as List?) ?? [],
    );
  }

  static TaskStatus _mapStatus(String status) {
    switch (status) {
      case 'active':
      case 'doing':
      case 'inprogress':
        return TaskStatus.doing;
      case 'pending':
      case 'todo':
        return TaskStatus.pending;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      case 'urgent':
        return TaskStatus.urgent;
      default:
        return TaskStatus.pending;
    }
  }

  static IconData _mapIcon(String status) {
    switch (status) {
      case 'active':
      case 'doing':
      case 'inprogress':
        return Icons.play_circle_fill;
      case 'completed':
      case 'done':
        return Icons.check_circle;
      case 'urgent':
        return Icons.warning_amber_rounded;
      default:
        return Icons.assignment;
    }
  }

  String get fullLocation {
    if (bed.isNotEmpty) {
      return '$field - $area - $bed';
    }
    return '$field - $area';
  }

  String get timeRange {
    if (startDate != null) {
      return DateFormat('HH:mm').format(startDate!.toLocal());
    }
    return '--:--';
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? taskType,
    String? season,
    String? cropName,
    String? field,
    String? area,
    String? bed,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? bedIds,
    List<String>? plotIds,
    String? date,
    TaskStatus? status,
    bool? isUrgent,
    String? assignedBy,
    String? assignedRole,
    IconData? avatarIcon,
    String? imageAsset,
    DateTime? taskScheduledAt,
    String? rawStatus,
    String? assignedToWorkerId,
    String? seasonId,
    List<dynamic>? taskDetails,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      season: season ?? this.season,
      cropName: cropName ?? this.cropName,
      field: field ?? this.field,
      area: area ?? this.area,
      bed: bed ?? this.bed,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bedIds: bedIds ?? this.bedIds,
      plotIds: plotIds ?? this.plotIds,
      date: date ?? this.date,
      status: status ?? this.status,
      isUrgent: isUrgent ?? this.isUrgent,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedRole: assignedRole ?? this.assignedRole,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      imageAsset: imageAsset ?? this.imageAsset,
      taskScheduledAt: taskScheduledAt ?? this.taskScheduledAt,
      rawStatus: rawStatus ?? this.rawStatus,
      assignedToWorkerId: assignedToWorkerId ?? this.assignedToWorkerId,
      seasonId: seasonId ?? this.seasonId,
      taskDetails: taskDetails ?? this.taskDetails,
    );
  }
}

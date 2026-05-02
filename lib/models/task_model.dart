import 'package:flutter/material.dart';

enum TaskStatus { doing, pending, completed, urgent }

class TaskModel {
  String id;
  String title;
  TaskStatus status;
  String description;
  List<String> bedIds;
  List<String> plotIds;
  String timeRange;
  String seasonId;
  IconData avatarIcon;
  String season;
  String taskType;
  bool isUrgent;
  String assignedBy;
  DateTime? startDate;
  DateTime? endDate;

  TaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.description,
    required this.bedIds,
    required this.plotIds,
    required this.timeRange,
    required this.seasonId,
    required this.avatarIcon,
    required this.season,
    required this.taskType,
    required this.isUrgent,
    required this.assignedBy,
    this.startDate,
    this.endDate,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    TaskStatus parseStatus(String? statusStr) {
      if (statusStr == null) return TaskStatus.pending;
      final s = statusStr.toLowerCase();
      if (s == 'completed') return TaskStatus.completed;
      if (s == 'doing' || s == 'inprogress') return TaskStatus.doing;
      if (s == 'urgent') return TaskStatus.urgent;
      return TaskStatus.pending;
    }

    String timeRangeVal = '';
    if (json['startDate'] != null && json['endDate'] != null) {
      final start = DateTime.parse(json['startDate']).toLocal();
      final end = DateTime.parse(json['endDate']).toLocal();
      final startStr =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
      timeRangeVal = '$startStr - $endStr';
    }

    IconData parseIcon(String t) {
      final lower = t.toLowerCase();
      if (lower.contains('tưới') || lower.contains('nước'))
        return Icons.water_drop;
      if (lower.contains('sâu bệnh') || lower.contains('thiệt hại'))
        return Icons.bug_report;
      return Icons.task_alt;
    }

    return TaskModel(
      id: json['taskDetailId'] ?? json['scheduleId'] ?? json['taskId'] ?? '',
      title: json['taskTitle'] ?? 'Không có tiêu đề',
      status: parseStatus(
          json['taskDetailStatus'] ?? json['status'] ?? json['taskStatus']),
      description:
          json['notes'] ?? json['description'] ?? json['taskNotes'] ?? '',
      bedIds: json['bedIds'] != null ? List<String>.from(json['bedIds']) : [],
      plotIds:
          json['plotIds'] != null ? List<String>.from(json['plotIds']) : [],
      timeRange: timeRangeVal,
      seasonId: json['seasonId'] ?? '',
      avatarIcon: parseIcon(json['taskTitle'] ?? ''),
      season: json['seasonName'] ?? '',
      taskType: 'Nhiệm vụ',
      isUrgent: false,
      assignedBy: json['assignedBy'] ?? 'Quản lý',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate']).toLocal()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate']).toLocal()
          : null,
    );
  }
}

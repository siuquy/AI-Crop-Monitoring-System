import 'package:flutter/material.dart';

enum TaskStatus { doing, pending, completed, urgent }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String taskType;
  final String cropName;
  final String season;
  final String field;
  final String area;
  final String bed;
  final String startTime;
  final String endTime;
  final String date;
  final TaskStatus status;
  final bool isUrgent;
  final String assignedBy;
  final String assignedRole;
  final IconData avatarIcon;
  final String imageAsset;

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
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.status,
    required this.isUrgent,
    required this.assignedBy,
    required this.assignedRole,
    required this.avatarIcon,
    required this.imageAsset,
  });

  // 🔥 THÊM 2 GETTER NÀY

  String get fullLocation {
    if (bed.isNotEmpty) {
      return '$field - $area - $bed';
    }
    return '$field - $area';
  }

  String get timeRange {
    if (endTime.isEmpty) {
      return startTime;
    }
    return '$startTime - $endTime';
  }
}

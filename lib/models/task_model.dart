import 'package:flutter/material.dart';

enum TaskStatus {
  urgent,
  doing,
  pending,
  completed,
}

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

  String get fullLocation => '$field – $area – $bed';

  String get timeRange => '$startTime – $endTime';
}

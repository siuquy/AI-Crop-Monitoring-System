import 'package:flutter/material.dart';

enum TaskStatus { pending, doing, completed, urgent }

class TaskModel {
  String id;
  String title;
  String description;
  TaskStatus status;
  String seasonId;
  List<String> bedIds;
  List<String> plotIds;
  String taskType;
  bool isUrgent;
  String imageAsset;
  String assignedBy;
  String assignedRole;
  DateTime? startDate;
  DateTime? endDate;

  String cropName;
  String season;
  String field;
  String area;
  String bed;
  String date;
  String timeRange;
  IconData avatarIcon;
  String rawStatus;
  String assignedToWorkerId;
  List<dynamic> taskDetails;
  DateTime? taskScheduledAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.seasonId,
    required this.bedIds,
    this.plotIds = const [],
    required this.taskType,
    required this.isUrgent,
    required this.imageAsset,
    required this.assignedBy,
    required this.assignedRole,
    this.startDate,
    this.endDate,
    this.cropName = 'Chưa có dữ liệu',
    this.season = '',
    this.field = 'Chưa có dữ liệu',
    this.area = 'Chưa có dữ liệu',
    this.bed = 'Chưa có dữ liệu',
    this.date = 'Hôm nay',
    this.timeRange = 'Trong ngày',
    this.avatarIcon = Icons.task_alt,
    this.rawStatus = '',
    this.assignedToWorkerId = '',
    this.taskDetails = const [],
    this.taskScheduledAt,
  });
}

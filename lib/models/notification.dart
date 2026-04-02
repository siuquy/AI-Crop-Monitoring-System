enum NotificationType {
  taskAssigned,
  reportApproved,
  reportNeedsUpdate,
  general,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final String? entityId; // e.g., taskId or reportId

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type = NotificationType.general,
    this.entityId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: _mapType(json['type'] as String?),
      entityId: json['entityId'] as String?,
    );
  }

  static NotificationType _mapType(String? type) {
    switch (type?.toLowerCase()) {
      case 'task_assigned':
        return NotificationType.taskAssigned;
      case 'report_approved':
        return NotificationType.reportApproved;
      case 'report_needs_update':
        return NotificationType.reportNeedsUpdate;
      default:
        return NotificationType.general;
    }
  }
}

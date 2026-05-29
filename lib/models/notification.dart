enum NotificationType {
  taskAssigned,
  reportApproved,
  reportNeedsUpdate,
  sensorAlert,
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
      id: json['noteId'] ?? json['id'] ?? '',
      title: json['noteTitle'] ?? json['title'] ?? '',
      body: json['noteMessage'] ?? json['body'] ?? '',
      createdAt: DateTime.parse(json['noteCreatedAt'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      isRead: json['noteStatus'] == 'read' || json['isRead'] == true,
      type: _mapType(json['noteType'] ?? json['type']),
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
      case 'sensor_alert':
        return NotificationType.sensorAlert;
      default:
        return NotificationType.general;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; 
  final String referenceId;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.referenceId,
    required this.createdAt,
    this.isRead = false,
  });
}

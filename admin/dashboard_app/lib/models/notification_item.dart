class NotificationItem {
  String id;
  String message;
  DateTime createdAt;

  NotificationItem({required this.id, required this.message, DateTime? createdAt}) : this.createdAt = createdAt ?? DateTime.now();
}

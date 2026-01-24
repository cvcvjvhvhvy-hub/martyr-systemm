class AuditEntry {
  final String id;
  final String adminId;
  final String action; // e.g., 'update_complaint', 'add_attachment'
  final String targetType; // e.g., 'complaint', 'user', 'content'
  final String targetId;
  final DateTime at;
  final String? details;

  AuditEntry({required this.id, required this.adminId, required this.action, required this.targetType, required this.targetId, this.details, DateTime? at}) : at = at ?? DateTime.now();
}

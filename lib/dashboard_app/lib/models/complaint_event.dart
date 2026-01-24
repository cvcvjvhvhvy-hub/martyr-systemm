class ComplaintEvent {
  final String byAdminId;
  final String action;
  final DateTime at;
  final String? note;

  ComplaintEvent({required this.byAdminId, required this.action, DateTime? at, this.note}) : at = at ?? DateTime.now();
}

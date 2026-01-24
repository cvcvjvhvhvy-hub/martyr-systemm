class Complaint {
  final String id;
  String title;
  String body;
  String reporterId;
  String status; // new, in_progress, done
  String priority; // high, medium, low
  DateTime createdAt;
  DateTime updatedAt;
  List<String> attachments;
  int timeSpentSeconds; // added for time tracking
  List<dynamic> events; // store lightweight event records (map or ComplaintEvent)

  Complaint({
    required this.id,
    required this.title,
    required this.body,
    required this.reporterId,
    this.status = 'new',
    this.priority = 'medium',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    int? timeSpentSeconds, // added for time tracking
    List<dynamic>? events, // added for event history
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        attachments = attachments ?? [],
        timeSpentSeconds = timeSpentSeconds ?? 0,
        events = events ?? [];
}

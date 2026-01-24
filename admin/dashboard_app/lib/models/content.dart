class ContentItem {
  String id;
  String title;
  String body;
  bool published;
  DateTime? scheduledAt;

  ContentItem({required this.id, required this.title, required this.body, this.published = false, this.scheduledAt});

  ContentItem copyWith({String? id, String? title, String? body, bool? published, DateTime? scheduledAt}) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      published: published ?? this.published,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}

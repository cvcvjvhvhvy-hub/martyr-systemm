enum ViewType {
  home,
  stances,
  crimes,
  profile,
  martyrs,
  details,
  management
}

class Martyr {
  final String id;
  final String name;
  final String title;
  final String birthDate;
  final String martyrdomDate;
  final String cause;
  final String rank;
  final String job;
  final List<String> battles;
  final String bio;
  final String imageUrl;

  Martyr({
    required this.id,
    required this.name,
    required this.title,
    required this.birthDate,
    required this.martyrdomDate,
    required this.cause,
    required this.rank,
    required this.job,
    required this.battles,
    required this.bio,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'birthDate': birthDate,
      'martyrdomDate': martyrdomDate,
      'cause': cause,
      'rank': rank,
      'job': job,
      'battles': battles.join(','),
      'bio': bio,
      'imageUrl': imageUrl,
    };
  }

  factory Martyr.fromMap(Map<String, dynamic> map) {
    return Martyr(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      birthDate: map['birthDate'] ?? '',
      martyrdomDate: map['martyrdomDate'] ?? '',
      cause: map['cause'] ?? '',
      rank: map['rank'] ?? '',
      job: map['job'] ?? '',
      battles: (map['battles'] ?? '').toString().split(',').where((s) => s.isNotEmpty).toList(),
      bio: map['bio'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

class Stance {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;

  Stance({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
    };
  }

  factory Stance.fromMap(Map<String, dynamic> map) {
    return Stance(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
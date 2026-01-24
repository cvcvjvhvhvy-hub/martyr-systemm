class User {
  String id;
  String name;
  String email;
  String role;

  User({required this.id, required this.name, required this.email, this.role = 'user'});

  User copyWith({String? id, String? name, String? email, String? role}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

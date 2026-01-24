class AdminAccount {
  final String id;
  String name;
  String email;
  String role; // superadmin, content_admin, support_admin, tech_admin
  List<String> permissions;

  AdminAccount({required this.id, required this.name, required this.email, this.role = 'admin', List<String>? permissions})
      : permissions = permissions ?? [];
}

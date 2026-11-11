enum UserRole { student, staff, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.location,
    this.role = UserRole.student,
  });

  final String uid;
  final String name;
  final String email;
  final String department;
  final String location;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;

  /// Staff and admins see every report and can update status.
  bool get isStaff => role == UserRole.staff || role == UserRole.admin;
  String get firstName => name.split(' ').first;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
    uid: uid,
    name: data['name'] as String? ?? '',
    email: data['email'] as String? ?? '',
    department: data['department'] as String? ?? '',
    location: data['location'] as String? ?? '',
    role: UserRole.values.asNameMap()[data['role']] ?? UserRole.student,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'department': department,
    'location': location,
    'role': role.name,
  };
}

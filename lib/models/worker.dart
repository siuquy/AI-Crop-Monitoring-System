class Worker {
  final String id;
  final String fullName;
  final String role;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? email;

  Worker({
    required this.id,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
    this.email,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['userId'] ?? '',
      fullName: json['fullname'] ?? 'Không có tên',
      role: json['roleName'] ?? 'Nông dân', // Default role
      phoneNumber: json['phoneNumber'],
      avatarUrl: json['avatarUrl'],
      email: json['email'],
    );
  }
}

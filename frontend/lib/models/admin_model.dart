class Admin {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? userId;

  Admin({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.userId,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'],
    );
  }
}

class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final String role; // 'employee', 'hr', 'admin'
  final String? companyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    required this.role,
    this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      role: json['role'] ?? 'employee',
      companyId: json['companyId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'role': role,
      'companyId': companyId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? profileImage,
    String? role,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
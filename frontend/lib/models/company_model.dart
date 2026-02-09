class Company {
  final String id;
  final String name;
  final bool hasPin;
  final String role;
  final List<String> branchNames;
  final String? logo;
  final String? companyCode;
  final List<String>? users;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional extra metadata (not present in this response, keep nullable)
  final String? address;
  final String? email;
  final String? phone;
  final String? website;
  final double? latitude;
  final double? longitude;
  final double? attendanceRadius;

  Company({
    required this.id,
    required this.name,
    this.hasPin = false,
    this.role = 'employee',
    this.branchNames = const [],
    this.logo,
    this.companyCode,
    this.users,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.email,
    this.phone,
    this.website,
    this.latitude,
    this.longitude,
    this.attendanceRadius,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      // ✅ your API sends "_id", not "id"
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      hasPin: json['hasPin'] ?? false,
      role: json['role']?.toString() ?? 'employee',
          
      // Parse branch names safely
      branchNames: json['assignedBranchNames'] != null 
          ? List<String>.from(json['assignedBranchNames']) 
          : [],
      logo: json['logo'] == null ? null : json['logo'].toString(),
      companyCode:
          json['company_code'] == null ? null : json['company_code'].toString(),

      // ✅ list of strings
      users: json['users'] != null
          ? List<String>.from(json['users'].map((u) => u.toString()))
          : null,

      createdBy:
          json['created_by'] == null ? null : json['created_by'].toString(),

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,

      // ✅ optional extras (may be completely missing / null)
      address: json['address']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
      latitude: json['latitude'] == null
          ? null
          : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] == null
          ? null
          : double.tryParse(json['longitude'].toString()),
      attendanceRadius: json['attendanceRadius'] == null
          ? null
          : double.tryParse(json['attendanceRadius'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'logo': logo,
      'company_code': companyCode,
      'users': users,
      'created_by': createdBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'address': address,
      'email': email,
      'phone': phone,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'attendanceRadius': attendanceRadius,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? logo,
    String? companyCode,
    List<String>? users,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? address,
    String? email,
    String? phone,
    String? website,
    double? latitude,
    double? longitude,
    double? attendanceRadius,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      companyCode: companyCode ?? this.companyCode,
      users: users ?? this.users,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      attendanceRadius: attendanceRadius ?? this.attendanceRadius,
    );
  }

  String get displaySubtitle {
    // Capitalize the singular role
    String roleText = role[0].toUpperCase() + role.substring(1);
    
    // Append branches only if this specific item is a branch admin
    if (role == 'branch admin' && branchNames.isNotEmpty) {
      roleText += " (${branchNames.join(", ")})";
    }
    return roleText;
  }
}

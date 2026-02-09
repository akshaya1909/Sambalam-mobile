class CompanyUser {
  final String id;
  final String employeeId;
  final String name;
  final String role;
  final List<String> assignedBranches;
  final String? profilePic;
  final String jobTitle;
  final String phone;
  final bool hasFcmToken;

  CompanyUser({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.role,
    required this.assignedBranches,
    this.profilePic,
    required this.jobTitle,
    required this.phone,
    required this.hasFcmToken,
  });

  factory CompanyUser.fromJson(Map<String, dynamic> json) {
    // Helper function to safely extract a string from potentially a list or null
    String safeString(dynamic value, String fallback) {
      if (value == null) return fallback;
      if (value is List)
        return value.isNotEmpty ? value.first.toString() : fallback;
      return value.toString();
    }

    List<String> parseBranches(dynamic value) {
      if (value == null || value is! List) return [];
      return value.map((e) => e.toString()).toList();
    }

    return CompanyUser(
      id: safeString(json['_id'], ''),
      employeeId: safeString(json['employeeId'], ''),
      name: safeString(json['fullName'], 'Unknown'),
      role: safeString(json['role'], 'employee'),
      assignedBranches: parseBranches(json['assignedBranches']),
      profilePic: json['profilePic']?.toString(),
      jobTitle: safeString(json['jobTitle'], 'Staff'),
      phone: safeString(json['phoneNumber'], ''),
      hasFcmToken: json['hasFcmToken'] ?? false,
    );
  }

  String get initials {
    if (name.isEmpty || name == 'Unknown') return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  bool get isManager =>
      ['admin', 'manager', 'branch admin'].contains(role.toLowerCase());
}

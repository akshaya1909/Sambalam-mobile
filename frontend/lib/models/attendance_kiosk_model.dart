class AttendanceKiosk {
  final String id;
  final String name;
  final String dialCode;
  final String phone;
  final List<String> branchIds;
  final List<String> branchNames; // For UI display

  AttendanceKiosk({
    required this.id,
    required this.name,
    required this.dialCode,
    required this.phone,
    required this.branchIds,
    required this.branchNames,
  });

  factory AttendanceKiosk.fromJson(Map<String, dynamic> json) {
    List<String> bIds = [];
    List<String> bNames = [];

    if (json['branches'] != null) {
      final List<dynamic> branches = json['branches'];
      for (var b in branches) {
        if (b is Map) {
          bIds.add(b['id'] ?? b['_id'] ?? '');
          bNames.add(b['name'] ?? '');
        }
      }
    }

    return AttendanceKiosk(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      dialCode: json['dialCode'] ?? '+91',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      branchIds: bIds,
      branchNames: bNames,
    );
  }
}

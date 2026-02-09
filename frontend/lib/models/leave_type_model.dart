class LeaveType {
  final String id;
  final String name;
  final String code; // 'CASUAL', 'SICK', 'CUSTOM'

  LeaveType({
    required this.id,
    required this.name,
    required this.code,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? 'CUSTOM',
    );
  }
}

class CompanyBreak {
  final String id;
  final String name;
  final String type; // 'Paid' or 'Unpaid'
  final int durationHours;
  final int durationMinutes;

  CompanyBreak({
    required this.id,
    required this.name,
    required this.type,
    this.durationHours = 0,
    this.durationMinutes = 0,
  });

  factory CompanyBreak.fromJson(Map<String, dynamic> json) {
    return CompanyBreak(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Unpaid',
      durationHours: json['durationHours'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
    );
  }
}

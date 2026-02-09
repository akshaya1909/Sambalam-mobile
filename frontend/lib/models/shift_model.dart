class Shift {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String punchInRule;
  final String punchOutRule;
  final int punchInHours;
  final int punchInMinutes;
  final int punchOutHours;
  final int punchOutMinutes;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.punchInRule = 'Anytime',
    this.punchOutRule = 'Anytime',
    this.punchInHours = 0,
    this.punchInMinutes = 0,
    this.punchOutHours = 0,
    this.punchOutMinutes = 0,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      startTime: json['startTime'] ?? '09:00 AM',
      endTime: json['endTime'] ?? '06:00 PM',
      punchInRule: json['punchInRule'] ?? 'Anytime',
      punchOutRule: json['punchOutRule'] ?? 'Anytime',
      punchInHours: json['punchInHours'] ?? 0,
      punchInMinutes: json['punchInMinutes'] ?? 0,
      punchOutHours: json['punchOutHours'] ?? 0,
      punchOutMinutes: json['punchOutMinutes'] ?? 0,
    );
  }
}

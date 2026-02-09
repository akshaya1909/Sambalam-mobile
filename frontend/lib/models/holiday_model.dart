class Holiday {
  final String name;
  final String date; // YYYY-MM-DD
  final String type; // 'National' or 'Company'
  final String source; // 'calendarific' or 'manual'

  Holiday({
    required this.name,
    required this.date,
    this.type = 'Company',
    this.source = 'manual',
  });

  // Generates a unique ID consistent with the React logic for frontend tracking
  String get id {
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'(^-|-$)'), '');
    return '$date-$slug';
  }

  factory Holiday.fromJson(Map<String, dynamic> json) {
    String t = 'Company';
    if (json['type'] != null) {
      if (json['type'] is List && (json['type'] as List).isNotEmpty) {
        t = (json['type'] as List).first.toString();
      } else if (json['type'] is String) {
        t = json['type'];
      }
    }

    return Holiday(
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      type: t,
      source: json['source'] ?? 'manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'source': source,
      'type': [type],
    };
  }
}

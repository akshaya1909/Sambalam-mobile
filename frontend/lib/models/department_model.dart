class Department {
  final String id;
  final String name;
  final List<String> staffIds; // List of employee IDs

  Department({
    required this.id,
    required this.name,
    required this.staffIds,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    String extractedId = '';
    if (json['_id'] is Map && json['_id'].containsKey('\$oid')) {
      extractedId = json['_id']['\$oid'].toString();
    } else {
      extractedId = json['_id']?.toString() ?? '';
    }
    return Department(
      id: extractedId,
      name: json['name'] ?? '',
      // --- FIX IS HERE: Changed 'staff' to 'staffIds' ---
      staffIds: (json['staff'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // Getter for convenience (optional, allows you to use .staff)
  List<String> get staff => staffIds;
}

// Simple Employee model for the selection list
class Employee {
  final String id;
  final String name;
  final String? profilePic;

  Employee({required this.id, required this.name, this.profilePic});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['basic']?['fullName'] ?? 'Unknown',
      profilePic: json['basic']?['profilePic'],
    );
  }
}

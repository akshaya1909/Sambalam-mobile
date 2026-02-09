class EmployeeDocument {
  final String id;
  final String name;
  final String category;
  final String type; // 'pdf' or 'image'
  final String size;
  final String filePath;
  final DateTime uploadedOn;
  final bool verified;

  EmployeeDocument({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.size,
    required this.filePath,
    required this.uploadedOn,
    required this.verified,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      category: json['category'] ?? 'Other',
      type: json['type'] ?? 'file',
      size: json['size'] ?? '',
      filePath: json['filePath'] ?? '',
      uploadedOn: json['uploadedOn'] != null
          ? DateTime.parse(json['uploadedOn'])
          : DateTime.now(),
      verified: json['verified'] ?? false,
    );
  }
}

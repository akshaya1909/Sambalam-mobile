class IncentiveType {
  final String id;
  final String name;
  final String description;
  final bool isTaxable;
  final bool isActive;

  IncentiveType({
    required this.id,
    required this.name,
    required this.description,
    required this.isTaxable,
    required this.isActive,
  });

  factory IncentiveType.fromJson(Map<String, dynamic> json) {
    return IncentiveType(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isTaxable: json['isTaxable'] ?? true,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'isTaxable': isTaxable,
      'isActive': isActive,
    };
  }
}

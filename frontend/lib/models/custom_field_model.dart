class CustomField {
  final String id;
  final String name;
  final String type; // 'text', 'number', 'date', 'dropdown', 'checkbox'
  final bool isRequired;
  final String placeholder; // Maps to 'description' in UI
  final List<String> options;

  CustomField({
    required this.id,
    required this.name,
    required this.type,
    required this.isRequired,
    required this.placeholder,
    required this.options,
  });

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'text',
      isRequired: json['isRequired'] ?? false,
      placeholder: json['placeholder'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isRequired': isRequired,
      'placeholder': placeholder,
      'options': options,
    };
  }
}

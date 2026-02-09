class SalaryTemplate {
  final String id;
  final String name;
  final String description;
  final List<SalaryComponent> components;
  final bool isActive;

  SalaryTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.components,
    this.isActive = true,
  });

  factory SalaryTemplate.fromJson(Map<String, dynamic> json) {
    return SalaryTemplate(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      components: (json['components'] as List<dynamic>?)
              ?.map((e) => SalaryComponent.fromJson(e))
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'components': components.map((e) => e.toJson()).toList(),
      'isActive': isActive,
    };
  }
}

class SalaryComponent {
  final String name;
  final String type; // "earning" or "deduction"
  final String calculationType; // "percentage" or "flat"
  final double value;
  final bool isStatutory;

  SalaryComponent({
    required this.name,
    required this.type,
    this.calculationType = 'percentage',
    required this.value,
    this.isStatutory = false,
  });

  factory SalaryComponent.fromJson(Map<String, dynamic> json) {
    return SalaryComponent(
      name: json['name'] ?? '',
      type: json['type'] ?? 'earning',
      calculationType: json['calculationType'] ?? 'percentage',
      value: (json['value'] ?? 0).toDouble(),
      isStatutory: json['isStatutory'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'calculationType': calculationType,
      'value': value,
      'isStatutory': isStatutory,
    };
  }
}

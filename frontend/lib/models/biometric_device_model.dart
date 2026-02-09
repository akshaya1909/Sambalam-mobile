class BiometricDevice {
  final String id;
  final String deviceName;
  final String serialNumber;
  final List<String> branchIds;
  final List<String> branchNames; // For UI display

  BiometricDevice({
    required this.id,
    required this.deviceName,
    required this.serialNumber,
    required this.branchIds,
    required this.branchNames,
  });

  factory BiometricDevice.fromJson(Map<String, dynamic> json) {
    // Extract branches safely
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

    return BiometricDevice(
      id: json['id'] ?? json['_id'] ?? '',
      deviceName: json['deviceName'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      branchIds: bIds,
      branchNames: bNames,
    );
  }
}

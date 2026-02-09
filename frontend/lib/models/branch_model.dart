class Branch {
  final String id;
  final String name;
  final String address;
  final double radius;
  final double latitude;
  final double longitude;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.radius,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    String extractedId = '';
    if (json['_id'] is Map && json['_id'].containsKey('\$oid')) {
      extractedId = json['_id']['\$oid'].toString();
    } else {
      extractedId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    }
    // Handle nested location coordinates safely
    List<dynamic> coords = [80.2707, 13.0827]; // Default [lng, lat]
    if (json['location'] != null && json['location']['coordinates'] != null) {
      coords = json['location']['coordinates'];
    }

    return Branch(
      id: extractedId,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      radius: (json['radius'] ?? 100).toDouble(),
      // MongoDB is [Long, Lat], Google Maps is [Lat, Long]
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }
}

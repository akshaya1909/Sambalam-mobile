class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final NotificationData? data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      type: json['type'] ?? 'General',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data:
          json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class NotificationData {
  final String? employeeName;
  final String? employeePhoto;
  final String? image; // Selfie
  final String? address;
  final double? lat;
  final double? lng;
  final DateTime? eventTime;

  NotificationData({
    this.employeeName,
    this.employeePhoto,
    this.image,
    this.address,
    this.lat,
    this.lng,
    this.eventTime,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      employeeName: json['employeeName'],
      employeePhoto: json['employeePhoto'],
      image: json['image'],
      address: json['address'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      eventTime:
          json['eventTime'] != null ? DateTime.parse(json['eventTime']) : null,
    );
  }
}

class Attendance {
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkInImagePath;
  final String? checkOutImagePath;
  final String status; // 'present', 'half-day', 'absent'
  final String? remarks;

  Attendance({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkInImagePath,
    this.checkOutImagePath,
    required this.status,
    this.remarks,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      userId: json['userId'],
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      checkInLatitude: json['checkInLatitude'],
      checkInLongitude: json['checkInLongitude'],
      checkOutLatitude: json['checkOutLatitude'],
      checkOutLongitude: json['checkOutLongitude'],
      checkInImagePath: json['checkInImagePath'],
      checkOutImagePath: json['checkOutImagePath'],
      status: json['status'] ?? 'present',
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkInImagePath': checkInImagePath,
      'checkOutImagePath': checkOutImagePath,
      'status': status,
      'remarks': remarks,
    };
  }

  Attendance copyWith({
    String? id,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkInImagePath,
    String? checkOutImagePath,
    String? status,
    String? remarks,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkInImagePath: checkInImagePath ?? this.checkInImagePath,
      checkOutImagePath: checkOutImagePath ?? this.checkOutImagePath,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}
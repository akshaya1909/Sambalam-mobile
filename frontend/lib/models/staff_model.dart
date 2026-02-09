import 'package:flutter/material.dart';

class Staff {
  final String id;
  final String name;
  final String phone;
  final String employeeId;
  final String lastLogin;
  final String? imageUrl;
  final Color? avatarColor;
  final DateTime? dateOfJoining;
  final String? status;
  final String? employmentStatus;
  final String? attendanceStatus;
  final String? hoursWorked;
  final String? inTimeIst;
  final String? punchInAddress;
  final String? punchInPhoto;
  final String? address;
  final String? punchOutTimeIst; // NEW
  final String? punchOutAddress; // NEW
  final String? punchOutPhoto;
  final bool isHalfDay;
  final bool isOvertime;

  Staff({
    required this.id,
    required this.name,
    required this.phone,
    required this.employeeId,
    required this.lastLogin,
    this.imageUrl,
    this.avatarColor,
    this.dateOfJoining,
    this.status,
    this.employmentStatus,
    this.attendanceStatus,
    this.hoursWorked,
    this.inTimeIst,
    this.punchInAddress,
    this.punchInPhoto,
    this.address,
    this.punchOutTimeIst,
    this.punchOutAddress,
    this.punchOutPhoto,
    this.isHalfDay = false,
    this.isOvertime = false,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    String extractedId = '';

    if (json['id'] != null) {
      extractedId = json['id'].toString();
    } else if (json['_id'] != null) {
      if (json['_id'] is Map && json['_id'].containsKey('\$oid')) {
        // Extract the hex string from the nested $oid object
        extractedId = json['_id']['\$oid'].toString();
      } else {
        extractedId = json['_id'].toString();
      }
    }
    return Staff(
      id: extractedId,
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      employeeId: json['employeeId'] ?? '',
      lastLogin: json['lastLogin'] ?? 'Never',
      dateOfJoining: json['dateOfJoining'] != null
          ? DateTime.parse(json['dateOfJoining'])
          : null,
      status: json['status'] as String?,
      employmentStatus: json['employmentStatus'] as String?,
      attendanceStatus: json['attendanceStatus'] as String?,
      hoursWorked: json['hoursWorked'] as String?,
      inTimeIst: json['inTimeIst'],
      punchInAddress: json['punchInAddress'],
      punchInPhoto: json['punchInPhoto'],
      address: json['address'] as String?,
      punchOutTimeIst: json['punchOutTimeIst'] as String?, // NEW
      punchOutAddress: json['punchOutAddress'] as String?, // NEW
      punchOutPhoto: json['punchOutPhoto'] as String?,
      isHalfDay: json['isHalfDay'] ?? false,
      isOvertime: json['isOvertime'] ?? false,
    );
  }
}

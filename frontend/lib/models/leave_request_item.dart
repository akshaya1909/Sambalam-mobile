import 'package:flutter/material.dart';

class LeaveRequestItem {
  final String id;
  final String employeeId;
  final String name;
  final String initials;
  final DateTime fromDate;
  final DateTime toDate;
  final bool isHalfDay;
  final String type;
  final String leaveTypeName;
  final String reason;
  final String? documentUrl;
  final String status;
  final DateTime requestedAt;
  final String durationLabel;

  final Color? color; // for avatar background, optional

  LeaveRequestItem({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.initials,
    required this.fromDate,
    required this.toDate,
    required this.isHalfDay,
    required this.type,
    required this.leaveTypeName,
    required this.reason,
    required this.documentUrl,
    required this.status,
    required this.requestedAt,
    required this.durationLabel,
    this.color,
  });

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) {
    DateTime parseToLocal(String key) {
      final raw = json[key];
      if (raw == null) return DateTime.now();
      final dt = DateTime.parse(raw as String);
      return dt
          .toLocal(); // <- convert from UTC to device local (IST on your phone)
    }

    return LeaveRequestItem(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] as String,
      name: json['name'] as String,
      initials: (json['initials'] ?? '').toString(),
      fromDate: parseToLocal('fromDate'),
      toDate: parseToLocal('toDate'),
      isHalfDay: json['isHalfDay'] as bool? ?? false,
      type: json['type']?.toString() ?? '',
      // Map leaveType name from populated backend object
      leaveTypeName: json['leaveTypeName'] ?? 'Unspecified',
      reason: json['reason'] as String? ?? '',
      documentUrl: json['documentUrl'] as String?,
      status: json['status'] as String? ?? 'pending',
      requestedAt: parseToLocal('requestedAt'),
      durationLabel: json['durationLabel'] as String? ?? '',
    );
  }
}

extension LeaveRequestItemExt on LeaveRequestItem {
  String get displayInitial {
    if (initials.trim().isNotEmpty) {
      return initials.trim()[0].toUpperCase();
    }
    if (name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    return 'U'; // fallback
  }
}

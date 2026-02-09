// lib/api/attendance_admin_api_service.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceAdminApiService {
  static const String baseUrl = 'http://10.80.210.30:5000';

  Future<Map<String, dynamic>> updateStatus({
    required String employeeId,
    required String companyId,
    required DateTime date,
    required String status, // "Absent" etc.
    String? leaveId,
    // required String token, // admin JWT
  }) async {
    final url = Uri.parse('$baseUrl/api/attendance/status');
    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'employeeId': employeeId,
        'companyId': companyId,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'status': status,
        'leaveId': leaveId,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update status: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> adminPunchIn({
    required String employeeId,
    required String companyId,
    required DateTime date, // date for that record
    required TimeOfDay time, // selected time
  }) async {
    // merge selected time into the chosen date
    final punchDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final url = Uri.parse('$baseUrl/api/attendance/admin/punch-in');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'companyId': companyId,
        'isoTime': punchDateTime.toIso8601String(),
        'punchedFrom': 'Web',
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to punch in: ${res.body}');
    }
  }

  // Future<Map<String, dynamic>> getRecord({
  //   required String employeeId,
  //   required String companyId,
  //   required DateTime date,
  // }) async {
  //   final url = Uri.parse('$baseUrl/api/attendance/record');
  //   final res = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'employeeId': employeeId,
  //       'companyId': companyId,
  //       'date': DateTime(date.year, date.month, date.day).toIso8601String(),
  //     }),
  //   );

  //   if (res.statusCode >= 200 && res.statusCode < 300) {
  //     return jsonDecode(res.body) as Map<String, dynamic>;
  //   } else {
  //     throw Exception('Failed to load attendance record: ${res.body}');
  //   }
  // }

  Future<Map<String, dynamic>> adminPunchOut({
    required String employeeId,
    required String companyId,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    // combine date + time to single DateTime and send as ISO
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final body = {
      'employeeId': employeeId,
      'companyId': companyId,
      'isoTime': dt.toUtc().toIso8601String(),
      'punchedFrom': 'Web',
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/attendance/admin/punch-out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Punch out failed: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deletePunchIn({
    required String employeeId,
    required String companyId,
    required DateTime date,
  }) async {
    final body = {
      'employeeId': employeeId,
      'companyId': companyId,
      'date':
          DateTime(date.year, date.month, date.day).toUtc().toIso8601String(),
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/attendance/admin/punch-in/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Delete punch in failed: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deletePunchOut({
    required String employeeId,
    required String companyId,
    required DateTime date,
  }) async {
    final body = {
      'employeeId': employeeId,
      'companyId': companyId,
      'date':
          DateTime(date.year, date.month, date.day).toUtc().toIso8601String(),
    };

    final res = await http.post(
      Uri.parse('$baseUrl/api/attendance/admin/punch-out/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Delete punch out failed: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_settings_model.dart';

class AttendanceApiService {
  static const String baseUrl = 'http://10.80.210.30:5000'; // same as company

  Future<Map<String, dynamic>> punchAttendance({
    required String employeeId,
    required String companyId,
    required String punchedFrom, // "Mobile"
    required File photoFile, // captured selfie
    double? lat,
    double? lng,
    String? address,
  }) async {
    final uri = Uri.parse('$baseUrl/api/attendance/punch');

    final request = http.MultipartRequest('POST', uri)
      ..fields['employeeId'] = employeeId
      ..fields['companyId'] = companyId
      ..fields['punchedFrom'] = punchedFrom;

    if (lat != null && lng != null) {
      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
    }
    if (address != null) {
      request.fields['address'] = address;
    }

    request.files.add(
      await http.MultipartFile.fromPath('photo', photoFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to punch attendance: ${response.body}');
    }
  }

  // get today status to know PunchIn / PunchOut
  Future<Map<String, dynamic>> getTodayStatus({
    required String employeeId,
    required String companyId,
  }) async {
    final uri = Uri.parse(
        '$baseUrl/api/attendance/today-status?employeeId=$employeeId&companyId=$companyId');

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load today status');
    }
  }

  Future<Map<String, dynamic>> getMonthlyAttendance({
    required String employeeId,
    required String companyId,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/attendance/monthly'
      '?employeeId=$employeeId&companyId=$companyId&year=$year&month=$month',
    );

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load monthly attendance: ${res.body}');
    }
  }

  Future<void> updateRemarks({
    required String employeeId,
    required String companyId,
    required DateTime date,
    required String remarks,
  }) async {
    final uri =
        Uri.parse('$baseUrl/api/attendance/$companyId/$employeeId/remarks');
    final res = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': date.toIso8601String(),
        'remarks': remarks,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to update remarks');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<AttendanceSettings?> getAttendanceSettings(String employeeId) async {
    // final token = await _getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/attendance/employee/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceSettings.fromJson(data);
      } else {
        print("Failed to load attendance: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching attendance settings: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWorkSchedule(String employeeId) async {
    final uri = Uri.parse('$baseUrl/api/attendance/schedule/$employeeId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['schedule'];
    }
    return null;
  }

  Future<void> triggerAutoMarkAbsent() async {
    final uri = Uri.parse('$baseUrl/api/attendance/trigger-auto-absent');
    final res = await http.post(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to trigger logic');
    }
  }
}

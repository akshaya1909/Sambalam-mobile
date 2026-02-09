import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceAlarmApiService {
  final String baseUrl = 'https://sambalam.ifoxclicks.com/api';

  Future<void> upsertMobileAlarm({
    required String employeeId,
    required String type, // "PunchIn" | "PunchOut"
    required int hour,
    required int minute,
  }) async {
    final url = Uri.parse('$baseUrl/attendance/mobile-alarm');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employeeId': employeeId,
        'type': type,
        'hour': hour,
        'minute': minute,
        'enabled': true,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception('Failed to save alarm: ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getMobileAlarms({
    required String employeeId,
  }) async {
    final url = Uri.parse('$baseUrl/attendance/$employeeId/mobile-alarms');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load alarms: ${res.body}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = decoded['mobileAlarms'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}

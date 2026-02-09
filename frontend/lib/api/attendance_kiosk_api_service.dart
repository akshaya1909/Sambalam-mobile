import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_kiosk_model.dart';
import '../models/branch_model.dart';

class AttendanceKioskApiService {
  // Update with your actual IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET KIOSKS ---
  Future<List<AttendanceKiosk>> getCompanyKiosks(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/attendance-kiosks/$companyId/kiosks');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List<dynamic> list = data['kiosks'];
      return list.map((e) => AttendanceKiosk.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load kiosks');
    }
  }

  // --- CREATE KIOSK ---
  Future<void> createKiosk(String companyId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/attendance-kiosks/$companyId/kiosks');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create kiosk: ${res.body}');
    }
  }

  // --- UPDATE KIOSK ---
  Future<void> updateKiosk(String kioskId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/attendance-kiosks/kiosks/$kioskId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update kiosk: ${res.body}');
    }
  }

  // --- DELETE KIOSK ---
  Future<void> deleteKiosk(String kioskId) async {
    final uri = Uri.parse('$baseUrl/api/attendance-kiosks/kiosks/$kioskId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete kiosk: ${res.body}');
    }
  }

  // --- FETCH BRANCHES (Helper) ---
  Future<List<Branch>> getBranches(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/branches/$companyId/branches');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Branch.fromJson(e)).toList();
    }
    return [];
  }
}

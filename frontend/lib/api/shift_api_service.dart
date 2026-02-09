import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shift_model.dart';

class ShiftApiService {
  // Update with your actual backend IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET SHIFTS ---
  Future<List<Shift>> getCompanyShifts(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/shifts/company/$companyId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Shift.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load shifts');
    }
  }

  // --- CREATE SHIFT ---
  Future<void> createShift(String companyId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/shifts/$companyId');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create shift: ${res.body}');
    }
  }

  // --- UPDATE SHIFT ---
  Future<void> updateShift(String shiftId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/shifts/$shiftId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update shift: ${res.body}');
    }
  }

  // --- DELETE SHIFT ---
  Future<void> deleteShift(String shiftId) async {
    final uri = Uri.parse('$baseUrl/api/shifts/$shiftId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete shift: ${res.body}');
    }
  }
}

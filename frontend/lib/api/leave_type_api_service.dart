import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leave_type_model.dart';

class LeaveTypeApiService {
  // Update with your actual IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET LEAVE TYPES ---
  Future<List<LeaveType>> getLeaveTypes(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/leave-type/$companyId/leave-types');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      // Handle both array response or object with key
      List<dynamic> list = [];
      if (data is List) {
        list = data;
      } else if (data['leaveTypes'] != null) {
        list = data['leaveTypes'];
      }
      return list.map((e) => LeaveType.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load leave types');
    }
  }

  // --- CREATE LEAVE TYPE ---
  Future<void> createLeaveType(String companyId, String name) async {
    final uri = Uri.parse('$baseUrl/api/leave-type/$companyId/leave-types');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode != 201) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to create leave type');
    }
  }

  // --- UPDATE LEAVE TYPE ---
  Future<void> updateLeaveType(String leaveTypeId, String name) async {
    final uri = Uri.parse('$baseUrl/api/leave-type/leave-types/$leaveTypeId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update leave type');
    }
  }

  // --- DELETE LEAVE TYPE ---
  Future<void> deleteLeaveType(String leaveTypeId) async {
    final uri = Uri.parse('$baseUrl/api/leave-type/leave-types/$leaveTypeId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete leave type');
    }
  }
}

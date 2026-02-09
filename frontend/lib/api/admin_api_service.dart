import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_model.dart';

class AdminApiService {
  // Update with your actual IP address
  static const String baseUrl = 'http://10.80.210.30:5000';

  // --- GET ADMINS ---
  // GET /:companyId/admins
  Future<List<Admin>> getCompanyAdmins(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/admins/$companyId/admins');

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['admins'];
          return list.map((e) => Admin.fromJson(e)).toList();
        }
      }
      throw Exception('Failed to load admins');
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // --- CREATE ADMIN ---
  // POST /:companyId/admins
  Future<void> createAdmin({
    required String companyId,
    required String name,
    required String phone,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admins/$companyId/admins');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phoneNumber': phone, // Backend expects 'phoneNumber'
          'email': email,
        }),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        final body = json.decode(res.body);
        throw Exception(body['message'] ?? 'Failed to create admin');
      }
    } catch (e) {
      throw Exception('Error creating admin: $e');
    }
  }

  // --- UPDATE ADMIN ---
  // PUT /admins/:adminId
  Future<void> updateAdmin({
    required String adminId,
    required String name,
    required String phone,
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admins/admins/$adminId');

    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phoneNumber': phone,
          'email': email,
        }),
      );

      if (res.statusCode != 200) {
        final body = json.decode(res.body);
        throw Exception(body['message'] ?? 'Failed to update admin');
      }
    } catch (e) {
      throw Exception('Error updating admin: $e');
    }
  }

  // --- DELETE ADMIN ---
  // DELETE /admins/:adminId
  Future<void> deleteAdmin(String adminId, String companyId) async {
    final uri =
        Uri.parse('$baseUrl/api/admins/admins/$adminId?companyId=$companyId');

    try {
      final res = await http.delete(uri);

      if (res.statusCode != 200) {
        final body = json.decode(res.body);
        throw Exception(body['message'] ?? 'Failed to delete admin');
      }
    } catch (e) {
      throw Exception('Error deleting admin: $e');
    }
  }

  Future<List<dynamic>> getPendingDeviceRequests(String companyId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/admins/device-requests/$companyId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load requests");
  }

  Future<void> processDeviceRequest(String requestId, String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admins/device-requests/$requestId/action'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"action": action}),
    );
    if (response.statusCode != 200) throw Exception("Action failed");
  }
}

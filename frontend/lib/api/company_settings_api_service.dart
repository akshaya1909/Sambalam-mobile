import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompanySettingsApiService {
  // Update with your actual IP address
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET SETTINGS (Re-uses getCompanyById) ---
  Future<Map<String, dynamic>> getCompanySettings(String companyId) async {
    // Assuming your main company route returns the full object including salarySettings
    final uri = Uri.parse('$baseUrl/api/company/$companyId');

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          // Return the 'data' or 'company' object from response
          return data['data'] ?? {};
        }
      }
      throw Exception('Failed to load settings');
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // --- UPDATE SETTINGS ---
  // PUT /api/company/:id/settings
  Future<void> updateCompanySettings({
    required String companyId,
    required Map<String, dynamic> payload,
  }) async {
    // Note: Adjust the route prefix ('/api/company') to match your server.js
    // Based on your snippet: router.put('/:id/settings', ...)
    final uri = Uri.parse('$baseUrl/api/company/$companyId/settings');

    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to update settings: ${res.body}');
      }
    } catch (e) {
      throw Exception('Error updating settings: $e');
    }
  }

  Future<String> getUserPhone(String userId) async {
    final uri = Uri.parse('$baseUrl/api/v1/$userId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['phoneNumber'] ?? '';
    }
    throw Exception('Failed to fetch user details');
  }

  // --- GET USER COMPANIES ---
  Future<List<Company>> getUserCompanies(String phoneNumber) async {
    final uri = Uri.parse('$baseUrl/api/company/user/$phoneNumber');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      // 1. Decode and explicitly cast as a List since your controller returns an array
      final dynamic decodedData = json.decode(res.body);

      if (decodedData is List) {
        return decodedData.map((e) => Company.fromJson(e)).toList();
      } else if (decodedData is Map && decodedData.containsKey('companies')) {
        // Handle the case where it might be wrapped in a 'companies' key
        final List<dynamic> list = decodedData['companies'];
        return list.map((e) => Company.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load companies: ${res.body}');
  }

  Future<void> deleteAllStaff(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/company/$companyId/staff/all');

    try {
      final res = await http.delete(uri);

      if (res.statusCode != 200) {
        final body = json.decode(res.body);
        throw Exception(body['message'] ?? 'Failed to delete staff');
      }
    } catch (e) {
      throw Exception('Error deleting staff: $e');
    }
  }

  Future<String> getUserIdFromPhone(String phone) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/v1/get-id/$phone'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['userId'];
      } else {
        throw Exception('User ID not found for this phone');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateUserRole({
    required String companyId,
    required String userId,
    required String role,
  }) async {
    final uri = Uri.parse('$baseUrl/api/company/$companyId/users/$userId/role');

    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );

      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating role: $e");
      return false;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/branch_model.dart';

class BranchApiService {
  // Update this IP to match your server configuration
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET BRANCHES ---
  Future<List<Branch>> getCompanyBranches(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/branches/$companyId/branches');

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Branch.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load branches: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // --- CREATE BRANCH ---
  Future<void> createBranch({
    required String companyId,
    required String name,
    required String address,
    required double radius,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/api/branches/$companyId/branches');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'address': address,
          'radius': radius,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (res.statusCode != 201) {
        throw Exception('Failed to create branch: ${res.body}');
      }
    } catch (e) {
      throw Exception('Error creating branch: $e');
    }
  }

  // --- UPDATE BRANCH ---
  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String address,
    required double radius,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/api/branches/$branchId');

    try {
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'address': address,
          'radius': radius,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to update branch: ${res.body}');
      }
    } catch (e) {
      throw Exception('Error updating branch: $e');
    }
  }

  // --- DELETE BRANCH ---
  Future<void> deleteBranch(String branchId) async {
    final uri = Uri.parse('$baseUrl/api/branches/$branchId');

    try {
      final res = await http.delete(uri);

      if (res.statusCode != 200) {
        throw Exception('Failed to delete branch: ${res.body}');
      }
    } catch (e) {
      throw Exception('Error deleting branch: $e');
    }
  }
}

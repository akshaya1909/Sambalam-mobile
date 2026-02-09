import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_user.dart';
import '../models/staff_model.dart';

class EmployeeApiService {
  static const String baseUrl = 'http://10.80.210.30:5000';

  Future<Map<String, dynamic>> getEmployeeBasicDetails({
    required String employeeId,
    required String companyId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/employees/basic?employeeId=$employeeId&companyId=$companyId',
    );

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load employee details: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getEmployeeProfileById({
    required String employeeId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/employees/profile/$employeeId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load employee profile: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getEmployeeByPhone({
    required String phoneNumber,
    required String companyId,
  }) async {
    final uri =
        Uri.parse('$baseUrl/api/employees/by-phone').replace(queryParameters: {
      'phoneNumber': phoneNumber,
      'companyId': companyId,
    });

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load employee by phone: ${res.body}');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // GET Company Users
  Future<List<CompanyUser>> getCompanyUsers(String companyId) async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/api/company/company-users/$companyId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CompanyUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load employees: ${response.body}');
    }
  }

  // PUT Update User Role
  Future<void> updateUserRole({
    required String companyId,
    required String userId,
    required String oldRole,
    required String newRole,
    List<String>? branchIds,
  }) async {
    final token = await _getToken();

    // Ensure URL matches backend route definition exactly
    // Backend: router.put('/:companyId/users/:userId/role', ...) mounted at /api/company
    final uri = Uri.parse('$baseUrl/api/company/$companyId/users/$userId/role');

    print("Requesting PUT: $uri"); // Debug print
    debugPrint("Body: ${jsonEncode({'oldRole': oldRole, 'newRole': newRole})}");

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldRole': oldRole,
        'newRole': newRole, // Matches const { oldRole, newRole } = req.body;
        'branchIds': branchIds ?? [],
      }),
    );

    if (response.statusCode != 200) {
      debugPrint("Error Response: ${response.body}");
      // Parse error message from backend if available
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to update role');
    }
  }

  Future<String?> toggleEmployeeStatus(String employeeId) async {
    final uri = Uri.parse('$baseUrl/api/employees/$employeeId/toggle-status');
    final response = await http.put(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status']; // Returns 'active' or 'inactive'
    } else {
      throw Exception('Failed to update status');
    }
  }

  Future<Staff?> getEmployeeById(String id) async {
    try {
      // 1. Get the current companyId from local storage
      final prefs = await SharedPreferences.getInstance();
      final String? companyId = prefs.getString('companyId');

      if (companyId == null) {
        debugPrint("Error: No companyId found in SharedPreferences");
        return null;
      }

      // 2. Append companyId as a query parameter (?companyId=...)
      final uri =
          Uri.parse('$baseUrl/api/employees/get/$id?companyId=$companyId');

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Since your backend returns { employee: { ... } }, map it correctly
        return Staff.fromJson(data['employee']);
      } else {
        debugPrint("Server Error ${res.statusCode}: ${res.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      return null;
    }
  }

  Future<String?> downloadBiodataPdf(String employeeId, String fullName) async {
    try {
      final dio = Dio();
      final String url = '$baseUrl/api/employees/biodata/$employeeId';

      // 1. Get correct directory
      final dir = await getExternalStorageDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // Use a clean filename without special characters
      final String cleanName =
          fullName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final String savePath =
          "${dir!.path}/Biodata_${cleanName}_$timestamp.pdf";

      // 2. Download with options to ensure we get bytes
      final response = await dio.download(
        url,
        savePath,
        options: Options(
          responseType: ResponseType.bytes, // Force bytes
          followRedirects: false,
        ),
      );

      if (response.statusCode == 200) {
        return savePath;
      } else {
        print("Server Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Download Error: $e");
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/company_model.dart';
import '../models/staff_model.dart';
import '../models/branch_model.dart'; // Import Branch Model
import '../models/department_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyApiService {
  static const String baseUrl =
      'http://10.80.210.30:5000'; // Update with your URL

  Future<Company?> getCompanyById(String companyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/company/$companyId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print(data);
        if (data['success']) {
          return Company.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching company: $e');
      return null;
    }
  }

  Future<List<Staff>> getCompanyStaffList({
    required String companyId,
    String? branchId,
  }) async {
    String url = '$baseUrl/api/company/staff?companyId=$companyId';
    if (branchId != null) {
      url += '&branchId=$branchId';
    }

    final uri = Uri.parse(url);
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> rawList = data['staffList'] ?? [];

      return rawList.map((e) => Staff.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load staff list: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getCompanyAttendanceStats({
    required String companyId,
    String? branchId,
  }) async {
    String url = '$baseUrl/api/attendance/stats?companyId=$companyId';
    if (branchId != null && branchId != 'ALL') {
      url += '&branchId=$branchId';
    }

    final uri = Uri.parse(url);
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load stats: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> getAdminCompanies() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('adminId'); // or whatever key you use

    if (adminId == null) {
      throw Exception('Admin ID not found in local storage');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/admin-details/companies/$adminId'),
      headers: {'Content-Type': 'application/json'},
    );
    // print('Raw API Response: ${response.body}'); // ← Debug

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load companies: ${response.body}');
    }
  }

  Future<List<Staff>> getCompanyLiveAttendanceList(String companyId,
      {String? branchId}) async {
    String url =
        '$baseUrl/api/attendance/company/live-attendance?companyId=$companyId';
    if (branchId != null) url += '&branchId=$branchId';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load live attendance');
    }

    final data = json.decode(res.body) as List<dynamic>;
    return data.map((e) => Staff.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Staff>> getCompanyDailyAttendanceList({
    required String companyId,
    required DateTime date,
    String? branchId,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date); // import intl
    String url =
        '$baseUrl/api/attendance/daily?companyId=$companyId&date=$dateStr';
    if (branchId != null) url += '&branchId=$branchId';

    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List data = json.decode(res.body) as List;
      return data
          .map((e) => Staff.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load daily attendance: ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getCompanyDetailsById(String companyId) async {
    final url = Uri.parse('$baseUrl/api/company/details/$companyId');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load company: ${res.body}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded['company'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCompany({
    required String companyId,
    required String name,
    required String category,
    required String address,
    required String gstNumber,
    required String udyamNumber,
    String?
        localFilePath, // CHANGED: Pass local path instead of URL string for updates
    Uint8List? webImageBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/company/details/$companyId');

    // 1. Create Multipart Request
    var request = http.MultipartRequest('PUT', uri);

    // 2. Add Text Fields
    request.fields['name'] = name;
    request.fields['category'] = category;
    request.fields['address'] = address;
    request.fields['gstNumber'] = gstNumber;
    request.fields['udyamNumber'] = udyamNumber;

    // 3. Add File (if user selected a new one)
    if (kIsWeb && webImageBytes != null) {
      // Handle Web Upload
      request.files.add(http.MultipartFile.fromBytes(
        'logo',
        webImageBytes,
        filename: 'company_logo.png',
      ));
    } else if (localFilePath != null && localFilePath.isNotEmpty) {
      // Handle Mobile Upload
      request.files
          .add(await http.MultipartFile.fromPath('logo', localFilePath));
    }

    // 4. Send Request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to update company: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['company'] as Map<String, dynamic>;
  }

  Future<List<Branch>> getCompanyBranches({required String companyId}) async {
    final uri = Uri.parse('$baseUrl/api/branches/$companyId/branches');
    // Ensure this route matches your backend. Based on BranchApiService provided earlier:
    // It might be '/api/branches/$companyId/branches' OR '/api/company/$companyId/branches'
    // I am using the path from your BranchApiService snippet.

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Branch.fromJson(e)).toList();
      } else {
        // Return empty list instead of throwing to prevent UI crash if feature not ready
        print('Failed to load branches: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching branches: $e');
      return [];
    }
  }

  // ✅ ADDED: Get Company Departments
  Future<List<Department>> getCompanyDepartments(
      {required String companyId}) async {
    final uri = Uri.parse('$baseUrl/api/department/company/$companyId');

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Department.fromJson(e)).toList();
      } else {
        print('Failed to load departments: ${res.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching departments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCompanyPlan(String companyId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/company/$companyId/plan'), // Ensure this route matches your backend
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching company plan: $e');
      return null;
    }
  }
}

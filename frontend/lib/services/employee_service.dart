import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // For MediaType

class EmployeeService {
  final String baseUrl =
      "http://10.80.210.30:5000/api/employees"; // Change to your local IP

  Future<Map<String, dynamic>> getEmployee(String id, String companyId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/get/$id?companyId=$companyId'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['employee'];
    }
    throw Exception('Failed to load employee');
  }

  Future<Map<String, dynamic>> getEmployeeByUserId(
      String id, String companyId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/user/$id?companyId=$companyId'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['employee'];
    }
    throw Exception('Failed to load employee');
  }

  Future<void> updatePersonalDetails(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/personal'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );
    if (response.statusCode != 200) throw Exception('Failed to update details');
  }

  Future<void> updateBasicDetails(String id, Map<String, dynamic> data) async {
    // Assuming you have a basic update route or reuse employment update
    final response = await http.put(
      Uri.parse('$baseUrl/$id/employment'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );
    if (response.statusCode != 200)
      throw Exception('Failed to update basic details');
  }

  Future<void> verifyAttribute(String id, String attribute) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$id/verify'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"attribute": attribute}),
    );
    if (response.statusCode != 200) throw Exception('Failed to verify');
  }

  Future<void> uploadDocument(String id, File file, String category) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/$id/documents'));

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType:
          MediaType('application', 'pdf'), // Adjust based on file type logic
    ));
    request.fields['category'] = category;
    request.fields['name'] = category;

    var response = await request.send();
    if (response.statusCode != 201) throw Exception('Upload failed');
  }

  Future<void> addPastEmployment(
      String id, String phone, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/employment/add-past-employment'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"phone": phone, "pastEmploymentData": data}),
    );
    if (response.statusCode != 200) throw Exception('Failed to add employment');
  }

  Future<List<Map<String, dynamic>>> getCompanyVerificationSummary(
      String companyId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/company/$companyId/verification-summary'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load verification summary');
  }

  // add this to your EmployeeService class
  Future<bool> createEmployee(Map<String, dynamic> employeeData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(employeeData),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        // This will help you see if it's a validation error or a crash
        // final errorBody = response.body;
        // debugPrint("Server Error Body: $errorBody");
        // final error = json.decode(errorBody);
        // throw Exception(
        //     error['message'] ?? 'Server Error (${response.statusCode})');
        throw response.body;
      }
    } catch (e) {
      debugPrint("Network/Parsing Error: $e");
      rethrow;
    }
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'), // Your backend route: PUT /api/employees/:id
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to update employee');
    }
  }

  Future<void> updateEmploymentDetails(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id/employment'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update employment details: ${response.body}');
    }
  }
}

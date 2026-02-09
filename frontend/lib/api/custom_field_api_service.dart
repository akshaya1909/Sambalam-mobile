import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/custom_field_model.dart';

class CustomFieldApiService {
  // Update with your actual IP address
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET CUSTOM FIELDS ---
  Future<List<CustomField>> getCustomFields(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/custom/$companyId/custom-fields');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      // Backend returns object { customFields: [...] }
      final List<dynamic> list = data['customFields'] ?? [];
      return list.map((e) => CustomField.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load custom fields');
    }
  }

  // --- CREATE CUSTOM FIELD ---
  Future<void> createCustomField(
      String companyId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/custom/$companyId/custom-fields');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to create custom field');
    }
  }

  // --- UPDATE CUSTOM FIELD ---
  Future<void> updateCustomField(
      String fieldId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/custom/custom-fields/$fieldId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to update custom field');
    }
  }

  // --- DELETE CUSTOM FIELD ---
  Future<void> deleteCustomField(String fieldId) async {
    final uri = Uri.parse('$baseUrl/api/custom/custom-fields/$fieldId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete custom field');
    }
  }

  // --- UPDATE EMPLOYEE VALUES ---
  Future<void> updateEmployeeCustomValues({
    required String employeeId,
    required List<Map<String, dynamic>> values,
  }) async {
    // Route: /api/employees/:id/custom-details
    final uri = Uri.parse('$baseUrl/api/employees/$employeeId/custom-details');

    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customFieldValues': values}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update custom details');
    }
  }
}

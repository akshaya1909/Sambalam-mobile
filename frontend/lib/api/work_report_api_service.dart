import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkReportApiService {
  static const String baseUrl =
      'https://sambalam.ifoxclicks.com/api/work-report';

  Future<bool> saveTemplate({
    String? templateId,
    required String companyId,
    required List<String> departmentIds,
    required bool isAllDepartments,
    required List<Map<String, dynamic>> fields,
    required String title,
  }) async {
    final uri = Uri.parse('$baseUrl/template/save');

    final formattedFields = fields
        .map((f) => {
              'label': f['label'],
              'fieldType': f['type'],
              'isRequired': f['is_required'] ?? true,
              'options': f['options'] ?? [],
            })
        .toList();

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'templateId': templateId,
        'companyId': companyId,
        'departmentIds': departmentIds, // Sends the array of IDs
        'isAllDepartments': isAllDepartments,
        'fields': formattedFields,
        'title': title,
      }),
    );

    return res.statusCode == 200;
  }

  // Fetch all templates for a company
  Future<List<dynamic>> getTemplates(String companyId) async {
    final uri = Uri.parse('$baseUrl/templates/$companyId');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to load templates');
  }

  // Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    final uri = Uri.parse('$baseUrl/template/$templateId');
    final res = await http.delete(uri);
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getMonthlyReports(
      String empId, int year, int month) async {
    final res = await http.get(Uri.parse(
        '$baseUrl/monthly?employeeId=$empId&year=$year&month=$month'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  Future<List<dynamic>> getTemplatesForEmployee(String empId) async {
    final res = await http.get(Uri.parse('$baseUrl/applicable/$empId'));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  Future<bool> submitReport(Map<String, dynamic> reportData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/submit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(reportData),
    );
    return res.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getDayReport(String empId, String date) async {
    final res = await http
        .get(Uri.parse('$baseUrl/day-report?employeeId=$empId&date=$date'));
    if (res.statusCode == 200 && res.body != "null") {
      return jsonDecode(res.body);
    }
    return null;
  }
}

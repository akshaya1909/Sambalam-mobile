import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salary_template_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalaryTemplateApiService {
  // Update with your actual server IP/URL
  static const String baseUrl =
      'https://sambalam.ifoxclicks.com/api/salary-templates';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Adjust key if needed
  }

  // GET All Templates
  Future<List<SalaryTemplate>> getSalaryTemplates(String companyId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/$companyId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SalaryTemplate.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load templates: ${response.body}');
    }
  }

  // CREATE Template
  Future<void> createSalaryTemplate(
      String companyId, SalaryTemplate template) async {
    final token = await _getToken();
    final body = template.toJson();
    body['companyId'] = companyId; // Add companyId to body

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create template: ${response.body}');
    }
  }

  // UPDATE Template
  Future<void> updateSalaryTemplate(String id, SalaryTemplate template) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(template.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update template: ${response.body}');
    }
  }

  // DELETE Template
  Future<void> deleteSalaryTemplate(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete template: ${response.body}');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/break_model.dart';

class BreakApiService {
  // Update with your actual backend IP
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET BREAKS ---
  Future<List<CompanyBreak>> getCompanyBreaks(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/company-breaks/company/$companyId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => CompanyBreak.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load breaks');
    }
  }

  // --- CREATE BREAK ---
  Future<void> createBreak(String companyId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/company-breaks/$companyId');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      throw Exception('Failed to create break: ${res.body}');
    }
  }

  // --- UPDATE BREAK ---
  Future<void> updateBreak(String breakId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/company-breaks/$breakId');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update break: ${res.body}');
    }
  }

  // --- DELETE BREAK ---
  Future<void> deleteBreak(String breakId) async {
    final uri = Uri.parse('$baseUrl/api/company-breaks/$breakId');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete break: ${res.body}');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incentive_type_model.dart';

class IncentiveApiService {
  // Update with your actual IP address
  static const String baseUrl = 'https://sambalam.ifoxclicks.com';

  // --- GET INCENTIVES ---
  Future<List<IncentiveType>> getIncentives(String companyId) async {
    final uri = Uri.parse('$baseUrl/api/incentives/company/$companyId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => IncentiveType.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load incentive types');
    }
  }

  // --- CREATE INCENTIVE ---
  Future<void> createIncentive(
      String companyId, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/incentives/company/$companyId');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 201) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to create incentive');
    }
  }

  // --- UPDATE INCENTIVE ---
  Future<void> updateIncentive(String id, Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/api/incentives/$id');
    final res = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Failed to update incentive');
    }
  }

  // --- DELETE INCENTIVE ---
  Future<void> deleteIncentive(String id) async {
    final uri = Uri.parse('$baseUrl/api/incentives/$id');
    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Failed to delete incentive');
    }
  }
}

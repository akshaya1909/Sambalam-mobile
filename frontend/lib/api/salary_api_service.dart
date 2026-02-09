import 'dart:convert';
import 'package:http/http.dart' as http;

class SalaryApiService {
  static const String baseUrl = 'http://10.80.210.30:5000/api/salary';

  Future<Map<String, dynamic>> getSalaryDetails(String employeeId) async {
    final response = await http.get(Uri.parse('$baseUrl/$employeeId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return {}; // Return empty if not found
    }
    throw Exception('Failed to load salary details');
  }

  Future<void> updateSalaryDetails(
      String employeeId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$employeeId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Update failed: ${response.body}');
    }
  }

  /// Fetches payable days and total days in month from the backend logic
  Future<Map<String, dynamic>> calculateDynamicPayableDays({
    required String employeeId,
    required String companyId,
    required int year,
    required int month,
  }) async {
    if (employeeId.isEmpty) {
      return {"success": false, "payableDays": 0.0, "totalDaysInMonth": 31};
    }
    final url = Uri.parse('$baseUrl/calculate').replace(queryParameters: {
      'employeeId': employeeId,
      'companyId': companyId,
      'year': year.toString(),
      'month': month.toString(),
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to calculate payable days: ${response.body}');
    }
  }
}
